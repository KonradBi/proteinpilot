import SwiftUI

struct InputMethodButtons: View {
    let onCameraPressed: () -> Void
    let onBarcodePressed: () -> Void
    let onVoicePressed: () -> Void
    let onManualPressed: () -> Void
    
    @State private var isRecordingVoice = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Camera Button
            InputMethodButton(
                icon: "camera.fill",
                title: "Kamera",
                subtitle: "Foto scannen",
                color: .blue,
                isActive: false,
                action: onCameraPressed
            )
            
            // Barcode Button
            InputMethodButton(
                icon: "barcode.viewfinder",
                title: "Barcode",
                subtitle: "Code scannen",
                color: .green,
                isActive: false,
                action: onBarcodePressed
            )
            
            // Voice Button
            InputMethodButton(
                icon: isRecordingVoice ? "stop.circle.fill" : "mic.fill",
                title: "Mikro",
                subtitle: "Sprechen",
                color: .orange,
                isActive: isRecordingVoice,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isRecordingVoice.toggle()
                    }
                    onVoicePressed()
                    
                    // Auto-stop after 5 seconds (demo)
                    if isRecordingVoice {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isRecordingVoice = false
                            }
                        }
                    }
                }
            )
            
            // Manual Button
            InputMethodButton(
                icon: "keyboard",
                title: "Manuell",
                subtitle: "Eingeben",
                color: .purple,
                isActive: false,
                action: onManualPressed
            )
        }
        .padding(.horizontal, 16)
    }
}

struct InputMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(
                            isActive ? 
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isActive ? 
                                    color.opacity(0.4) :
                                    Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isActive ? color.opacity(0.2) : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isActive ? color : .white.opacity(0.85))
                }
                .scaleEffect(isActive ? 1.1 : 1.0)
                
                // Labels
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black
        
        InputMethodButtons(
            onCameraPressed: { print("Camera pressed") },
            onBarcodePressed: { print("Barcode pressed") },
            onVoicePressed: { print("Voice pressed") },
            onManualPressed: { print("Manual pressed") }
        )
    }
}