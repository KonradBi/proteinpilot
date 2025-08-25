import SwiftUI

struct ProductConfirmationView: View {
    let scannedProduct: ScannedProduct
    let onConfirm: (FoodItem, Double) -> Void // FoodItem + quantity
    let onCancel: () -> Void
    
    @State private var selectedQuantity: Double
    @State private var customQuantity: String = ""
    @State private var useCustomQuantity = false
    
    // Pre-defined quantity options
    private let quantityOptions: [Double] = [50, 100, 150, 200, 250]
    
    init(scannedProduct: ScannedProduct, onConfirm: @escaping (FoodItem, Double) -> Void, onCancel: @escaping () -> Void) {
        self.scannedProduct = scannedProduct
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        // Initialize with serving size
        self._selectedQuantity = State(initialValue: scannedProduct.servingSize)
    }
    
    private var finalQuantity: Double {
        if useCustomQuantity {
            return Double(customQuantity) ?? selectedQuantity
        } else {
            return selectedQuantity
        }
    }
    
    private var calculatedProtein: Double {
        return (scannedProduct.proteinPer100g * finalQuantity) / 100.0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Product Header
                VStack(spacing: 16) {
                    // Product Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.8, blue: 0.2),
                                        Color(red: 0.1, green: 0.6, blue: 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(
                                color: Color.green.opacity(0.3),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        
                        Text(scannedProduct.suggestedEmoji)
                            .font(.system(size: 32))
                    }
                    
                    // Product Info
                    VStack(spacing: 8) {
                        Text(scannedProduct.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                        
                        if let brand = scannedProduct.brand, !brand.isEmpty {
                            Text("von \(brand)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Protein info
                        HStack(spacing: 16) {
                            Label("\(Int(scannedProduct.proteinPer100g))g/100g", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Label("Barcode", systemImage: "barcode.viewfinder")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
                
                // Quantity Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Menge auswählen:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Quick quantity buttons
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(quantityOptions, id: \.self) { quantity in
                            quantityButton(quantity)
                        }
                    }
                    
                    // Custom quantity toggle
                    Toggle("Eigene Menge eingeben", isOn: $useCustomQuantity)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if useCustomQuantity {
                        HStack {
                            TextField("Menge in Gramm", text: $customQuantity)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .onAppear {
                                    customQuantity = String(Int(selectedQuantity))
                                }
                            
                            Text("g")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Protein Preview
                proteinPreview
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Abbrechen") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Hinzufügen") {
                        let foodItem = scannedProduct.toFoodItem()
                        onConfirm(foodItem, finalQuantity)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .navigationTitle("Produkt bestätigen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func quantityButton(_ quantity: Double) -> some View {
        Button(action: {
            selectedQuantity = quantity
            useCustomQuantity = false
        }) {
            VStack(spacing: 6) {
                Text("\(Int(quantity))")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("g")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Show if this is the serving size
                if quantity == scannedProduct.servingSize {
                    Text("Portion")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        selectedQuantity == quantity && !useCustomQuantity ? 
                        Color.blue.opacity(0.2) : 
                        Color.gray.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                selectedQuantity == quantity && !useCustomQuantity ? 
                                Color.blue : 
                                Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var proteinPreview: some View {
        VStack(spacing: 12) {
            Text("Wird hinzugefügt:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                // Left: Product info
                VStack(alignment: .leading, spacing: 6) {
                    Text(scannedProduct.displayName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text("\(Int(finalQuantity))g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Show protein calculation
                    Text("\(String(format: "%.1f", scannedProduct.proteinPer100g))g pro 100g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
                
                // Right: Protein amount
                VStack(spacing: 4) {
                    Text("\(Int(calculatedProtein))")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("g PROTEIN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(1)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                                        Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
    }
}

#Preview {
    ProductConfirmationView(
        scannedProduct: ScannedProduct.sampleThunfisch,
        onConfirm: { foodItem, quantity in
            print("Confirmed: \(foodItem.name) - \(quantity)g")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}