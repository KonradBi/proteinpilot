import SwiftUI

struct PortionConfirmationView: View {
    let nutritionData: NutritionData
    let onConfirm: (NutritionData) -> Void
    let onCancel: () -> Void
    
    @State private var selectedPortion: PortionSize = .medium
    @State private var customWeight: String = ""
    @State private var useCustomWeight = false
    
    private var adjustedData: NutritionData {
        let multiplier = useCustomWeight ? 
            (Double(customWeight) ?? nutritionData.quantity) / nutritionData.quantity :
            selectedPortion.multiplier
            
        return NutritionData(
            quantity: nutritionData.quantity * multiplier,
            protein: nutritionData.protein * multiplier,
            foodName: nutritionData.foodName,
            confidence: nutritionData.confidence,
            estimationMethod: useCustomWeight ? .userInput : nutritionData.estimationMethod,
            referenceInfo: useCustomWeight ? 
                "\(Int(Double(customWeight) ?? nutritionData.quantity))g (angepasst)" :
                selectedPortion.description
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header mit erkanntem Food
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.85, blue: 0.0),
                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    
                    Text(nutritionData.foodName ?? "Erkanntes Lebensmittel")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    confidenceIndicator
                }
                
                // Portions-Auswahl
                VStack(alignment: .leading, spacing: 16) {
                    Text("Portion anpassen:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Standard Portionsgrößen
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(PortionSize.allCases, id: \.self) { portion in
                            portionButton(portion)
                        }
                    }
                    
                    // Custom Weight Toggle
                    Toggle("Genaues Gewicht eingeben", isOn: $useCustomWeight)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if useCustomWeight {
                        HStack {
                            TextField("Gewicht in Gramm", text: $customWeight)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            
                            Text("g")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Ergebnis-Preview
                resultPreview
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Hinzufügen") {
                        onConfirm(adjustedData)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .navigationTitle("Portion bestätigen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var confidenceIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: nutritionData.confidence > 0.8 ? "checkmark.circle.fill" : "questionmark.circle.fill")
                .foregroundColor(nutritionData.confidence > 0.8 ? .green : .orange)
            
            Text(confidenceText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    private var confidenceText: String {
        switch nutritionData.confidence {
        case 0.9...1.0:
            return "Sehr sicher erkannt"
        case 0.7..<0.9:
            return "Wahrscheinlich richtig"
        case 0.5..<0.7:
            return "Schätzung, bitte prüfen"
        default:
            return "Unsichere Erkennung"
        }
    }
    
    private func portionButton(_ portion: PortionSize) -> some View {
        Button(action: {
            selectedPortion = portion
            useCustomWeight = false
        }) {
            VStack(spacing: 8) {
                Text(portion.emoji)
                    .font(.title2)
                
                Text(portion.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("≈ \(Int(nutritionData.quantity * portion.multiplier))g")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPortion == portion && !useCustomWeight ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                selectedPortion == portion && !useCustomWeight ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var resultPreview: some View {
        VStack(spacing: 12) {
            Text("Wird hinzugefügt:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(adjustedData.foodName ?? "Lebensmittel")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text("\(Int(adjustedData.quantity))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let info = adjustedData.referenceInfo {
                        Text(info)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("\(Int(adjustedData.protein))")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.blue)
                    
                    Text("g PROTEIN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

enum PortionSize: String, CaseIterable {
    case small = "Klein"
    case medium = "Mittel"
    case large = "Groß"
    
    var multiplier: Double {
        switch self {
        case .small: return 0.7
        case .medium: return 1.0
        case .large: return 1.3
        }
    }
    
    var emoji: String {
        switch self {
        case .small: return "🤏"
        case .medium: return "👌"
        case .large: return "✋"
        }
    }
    
    var description: String {
        return "\(rawValue.lowercased())e Portion"
    }
}

#Preview {
    PortionConfirmationView(
        nutritionData: NutritionData(
            quantity: 120,
            protein: 22,
            foodName: "Hühnerbein (geschätzt)",
            confidence: 0.6,
            estimationMethod: .visualEstimation,
            referenceInfo: "etwa mittelgroß"
        ),
        onConfirm: { _ in print("Confirmed") },
        onCancel: { print("Cancelled") }
    )
}