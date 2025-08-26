import SwiftUI
import AVFoundation
import UIKit

struct BarcodeView: View {
    let onResult: (BarcodeResult) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                BarcodeCamera(onResult: onResult)
                
                // Overlay
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Barcode scannen")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Halte die Kamera über einen Barcode")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }
}

struct BarcodeCamera: UIViewControllerRepresentable {
    let onResult: (BarcodeResult) -> Void
    
    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let viewController = BarcodeScannerViewController()
        viewController.onResult = onResult
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {
        // No updates needed
    }
}

class BarcodeScannerViewController: UIViewController {
    var onResult: ((BarcodeResult) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopScanning()
    }
    
    private func setupCamera() {
        // Check camera permission first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            onResult?(.failure(.cameraUnavailable))
            return
        case .notDetermined:
            // Request permission and set up camera after approval
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCameraSession()
                    } else {
                        self?.onResult?(.failure(.cameraUnavailable))
                    }
                }
            }
            return
        case .authorized:
            setupCameraSession()
        @unknown default:
            onResult?(.failure(.cameraUnavailable))
            return
        }
    }
    
    private func setupCameraSession() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else {
            onResult?(.failure(.cameraUnavailable))
            return
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            onResult?(.failure(.cameraUnavailable))
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                onResult?(.failure(.unknown("Cannot add video input")))
                return
            }
        } catch {
            onResult?(.failure(.unknown("Error creating video input: \(error)")))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .code128, .code39, .code93,
                .upce, .aztec, .dataMatrix, .qr
            ]
        } else {
            onResult?(.failure(.unknown("Cannot add metadata output")))
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard let previewLayer = previewLayer else {
            onResult?(.failure(.unknown("Cannot create preview layer")))
            return
        }
        
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    private func startScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopScanning() {
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        // Stop scanning to prevent multiple results
        stopScanning()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Process barcode lookup
        Task {
            do {
                if let foodItem = try await BarcodeService.shared.lookupBarcode(stringValue) {
                    let foodData = BarcodeData(
                        barcode: stringValue,
                        foodName: foodItem.name,
                        protein: foodItem.proteinPer100g,
                        quantity: 100.0, // Default portion
                        brand: foodItem.brand
                    )
                    
                    await MainActor.run {
                        onResult?(.success(foodData))
                    }
                } else {
                    await MainActor.run {
                        onResult?(.failure(.productNotFound))
                    }
                }
            } catch {
                await MainActor.run {
                    onResult?(.failure(.networkError))
                }
            }
        }
    }
}

// MARK: - Result Types

enum BarcodeResult {
    case success(BarcodeData)
    case failure(BarcodeError)
}

struct BarcodeData {
    let barcode: String
    let foodName: String?
    let protein: Double
    let quantity: Double
    let brand: String?
}

enum BarcodeError: Error {
    case cameraUnavailable
    case productNotFound
    case networkError
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .cameraUnavailable:
            return "Kamera nicht verfügbar"
        case .productNotFound:
            return "Produkt nicht gefunden"
        case .networkError:
            return "Netzwerkfehler"
        case .unknown(let message):
            return message
        }
    }
}

#Preview {
    BarcodeView { result in
        print("Barcode result: \(result)")
    }
}