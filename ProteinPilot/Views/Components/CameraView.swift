import SwiftUI
import AVFoundation

// MARK: - Result Types
struct NutritionData {
    let quantity: Double
    let protein: Double
    let foodName: String?
    let confidence: Double      // 0.0-1.0 AI confidence
    let estimationMethod: EstimationMethod
    let referenceInfo: String?  // "etwa handflächengroß", "mittelgroß"
}

enum EstimationMethod {
    case packageLabel       // Von Verpackung abgelesen
    case visualEstimation   // AI Größenschätzung
    case referenceObject    // Mit Referenzobjekt (Münze, Hand)
    case userInput         // User hat Portion angegeben
}

enum CameraResult {
    case success(NutritionData)
    case failure(Error)
}

struct FoodData {
    let quantity: Double  
    let protein: Double
    let foodName: String?
    let barcode: String
}

enum CameraBarcodeResult {
    case success(FoodData)
    case failure(Error)
}

// MARK: - Camera View
struct CameraView: View {
    let onResult: (CameraResult) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Kamera-Integration")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Hier würde die Kamera mit\nOpenAI Vision für Nährwert-Erkennung\nintegriert werden.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Demo buttons for different scenarios
                VStack(spacing: 12) {
                    Button("📷 Demo: Protein Pudding (Verpackung)") {
                        let demoData = NutritionData(
                            quantity: 200,
                            protein: 20,
                            foodName: "Ehrmann High Protein Pudding Vanille",
                            confidence: 0.95,
                            estimationMethod: .packageLabel,
                            referenceInfo: "von Verpackung abgelesen"
                        )
                        onResult(.success(demoData))
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("📷 Demo: Hühnerbein (geschätzt)") {
                        let demoData = NutritionData(
                            quantity: 120,
                            protein: 22,
                            foodName: "Hühnerbein",
                            confidence: 0.6,
                            estimationMethod: .visualEstimation,
                            referenceInfo: "mittelgroß, geschätzt"
                        )
                        onResult(.success(demoData))
                    }
                    .buttonStyle(.bordered)
                    
                    Button("📷 Demo: Lachs-Filet (mit Hand)") {
                        let demoData = NutritionData(
                            quantity: 150,
                            protein: 33,
                            foodName: "Lachsfilet",
                            confidence: 0.8,
                            estimationMethod: .referenceObject,
                            referenceInfo: "etwa handflächengroß"
                        )
                        onResult(.success(demoData))
                    }
                    .buttonStyle(.bordered)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Abbrechen") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Nährwerte scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Barcode View (Legacy in CameraView.swift)
struct CameraBarcodeView: View {
    let onResult: (CameraBarcodeResult) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openFoodFacts = OpenFoodFactsService.shared
    @State private var isLoading = false
    @State private var showingProductConfirmation = false
    @State private var scannedProduct: ScannedProduct?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Barcode icon
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Barcode-Scanner")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Hier würde der Barcode-Scanner\nmit Produktdatenbank-Integration\naktiviert werden.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Real demo with OpenFoodFacts lookup
                if isLoading {
                    ProgressView("Lade Produktdaten...")
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        Button("🏷️ Demo: Nutella (echter Barcode)") {
                            Task {
                                await scanDemoBarcode("3017620422003") // Nutella - definitiv in DB
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("🏷️ Demo: Coca Cola") {
                            Task {
                                await scanDemoBarcode("5449000000996") // Coca Cola - bekannt
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("🏷️ Demo: Dr. Oetker Pudding") {
                            Task {
                                await scanDemoBarcode("4000521006003") // Dr. Oetker Protein
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Button("Abbrechen") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Barcode scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingProductConfirmation) {
                if let product = scannedProduct {
                    ProductConfirmationView(
                        scannedProduct: product,
                        onConfirm: { foodItem, quantity in
                            // Convert to our result format
                            let protein = (foodItem.proteinPer100g * quantity) / 100.0
                            let result = FoodData(
                                quantity: quantity,
                                protein: protein,
                                foodName: foodItem.name,
                                barcode: product.barcode
                            )
                            onResult(.success(result))
                            showingProductConfirmation = false
                        },
                        onCancel: {
                            showingProductConfirmation = false
                            scannedProduct = nil
                        }
                    )
                }
            }
        }
    }
    
    private func scanDemoBarcode(_ barcode: String) async {
        isLoading = true
        
        do {
            if let product = try await openFoodFacts.lookupProduct(barcode: barcode) {
                print("✅ Product found: \(product.displayName)")
                scannedProduct = product
                showingProductConfirmation = true
            } else {
                print("❌ Product not found in OpenFoodFacts")
                // Fallback to manual entry or error
                _ = FoodData(
                    quantity: 100,
                    protein: 0,
                    foodName: "Unbekanntes Produkt (\(barcode))",
                    barcode: barcode
                )
                onResult(.failure(OpenFoodFactsError.noProductFound))
            }
        } catch {
            print("❌ OpenFoodFacts error: \(error)")
            onResult(.failure(error))
        }
        
        isLoading = false
    }
}

// MARK: - Previews
#Preview("Camera") {
    CameraView { result in
        switch result {
        case .success(let data):
            print("Camera success: \(data.protein)g protein")
        case .failure(let error):
            print("Camera error: \(error)")
        }
    }
}

#Preview("Barcode") {
    CameraBarcodeView { result in
        switch result {
        case .success(let data):
            print("Barcode success: \(data.protein)g protein")
        case .failure(let error):
            print("Barcode error: \(error)")
        }
    }
}