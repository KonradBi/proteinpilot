import SwiftUI

struct AddEntryView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var selectedTab = 0
    @State private var proteinAmount = ""
    @State private var quantity = ""
    @State private var foodName = ""
    @State private var mealType = "Snack"
    @State private var notes = ""
    @State private var showSaveAsCustom = false
    
    private let mealTypes = ["Frühstück", "Mittagessen", "Abendessen", "Snack"]
    
    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header
                VStack(spacing: 20) {
                    HStack {
                        Button("Abbrechen") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("Protein hinzufügen")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Fertig") {
                            addEntry()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                        .disabled(!canAddEntry)
                    }
                    .padding(.horizontal)
                    
                    // Modern Tab Selector
                    HStack(spacing: 0) {
                        ForEach(0..<4) { index in
                            Button(action: { selectedTab = index }) {
                                VStack(spacing: 8) {
                                    Image(systemName: tabIcon(for: index))
                                        .font(.title3)
                                    
                                    Text(tabTitle(for: index))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedTab == index 
                                        ? Color.blue.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                // Content Area
                ScrollView {
                    Group {
                        switch selectedTab {
                        case 0: manualEntryView
                        case 1: cameraEntryView
                        case 2: barcodeEntryView
                        case 3: voiceEntryView
                        default: manualEntryView
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color.blue.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "pencil"
        case 1: return "camera.fill"
        case 2: return "barcode.viewfinder"
        case 3: return "mic.fill"
        default: return "pencil"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Manuell"
        case 1: return "Kamera"
        case 2: return "Barcode"
        case 3: return "Voice"
        default: return "Manuell"
        }
    }
    
    private var manualEntryView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Lebensmittel")
                    .font(.headline)
                
                TextField("z.B. Hühnerbrust, Protein Shake", text: $foodName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onSubmit { isTextFieldFocused = false }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menge (g)")
                        .font(.headline)
                    
                    TextField("100", text: $quantity)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .focused($isTextFieldFocused)
                        .onSubmit { isTextFieldFocused = false }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Protein (g)")
                        .font(.headline)
                    
                    TextField("25", text: $proteinAmount)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .onSubmit { isTextFieldFocused = false }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mahlzeit")
                    .font(.headline)
                
                Picker("Mahlzeit", selection: $mealType) {
                    ForEach(mealTypes, id: \.self) { meal in
                        Text(meal).tag(meal)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notizen (optional)")
                    .font(.headline)
                
                TextField("Zusätzliche Informationen", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)
            }
            
            HStack {
                Button("Als Vorlage speichern") {
                    if let protein = Double(proteinAmount), protein > 0 {
                        _ = dataManager.createCustomFoodItem(name: foodName.isEmpty ? "Eigene Quelle" : foodName, proteinPer100g: protein)
                        showSaveAsCustom = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showSaveAsCustom = false }
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .overlay(alignment: .top) {
            if showSaveAsCustom {
                Text("Gespeichert: Schnelle Quelle hinzugefügt")
                    .font(.caption)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.15)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.4)))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var cameraEntryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Kamera-Erkennung")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Fotografiere Nährwertangaben oder Verpackungen um automatisch Proteingehalt zu erkennen")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // TODO: Implement camera functionality
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Kamera öffnen")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Text("In der aktuellen Version noch nicht verfügbar")
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding()
    }
    
    private var barcodeEntryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Barcode Scanner")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Scanne den Barcode von Lebensmitteln um automatisch Nährwerte abzurufen")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // TODO: Implement barcode scanning
            }) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                    Text("Scanner öffnen")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Text("In der aktuellen Version noch nicht verfügbar")
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding()
    }
    
    private var voiceEntryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Spracheingabe")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Sage z.B. '200 Gramm Skyr' oder '30 Gramm Protein Shake'")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // TODO: Implement voice input
            }) {
                HStack {
                    Image(systemName: "mic")
                    Text("Aufnahme starten")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Text("In der aktuellen Version noch nicht verfügbar")
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding()
    }
    
    
    private var canAddEntry: Bool {
        if selectedTab == 0 {
            return !proteinAmount.isEmpty && Double(proteinAmount) != nil && Double(proteinAmount)! > 0
        }
        return false
    }
    
    private func addEntry() {
        guard selectedTab == 0,
              let proteinValue = Double(proteinAmount),
              proteinValue > 0 else { return }
        
        let quantityValue = Double(quantity) ?? proteinValue
        
        dataManager.addProteinEntry(
            quantity: quantityValue,
            proteinGrams: proteinValue,
            mealType: mealType
        )
        
        dismiss()
    }
}

#Preview {
    AddEntryView()
        .environmentObject(DataManager.shared)
}