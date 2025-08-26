import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var currentStep = 0
    @FocusState private var isTextFieldFocused: Bool
    @State private var bodyWeight = ""
    @State private var selectedGoal = "Muskeln aufbauen"
    @State private var selectedCookingSkill = "Anfänger"
    @State private var eatingWindowStart = Date()
    @State private var eatingWindowEnd = Date()
    @State private var noGos: [String] = []
    @State private var showingCustomNoGo = false
    @State private var customNoGo = ""
    
    private let goals = ["Muskeln aufbauen", "Gewicht halten", "Abnehmen", "Zunehmen"]
    private let cookingSkills = ["Anfänger", "Fortgeschritten", "Profi"]
    private let commonNoGos = ["Laktose", "Gluten", "Nüsse", "Soja", "Fleisch", "Fisch", "Eier"]
    
    var proteinTarget: Double {
        guard let weight = Double(bodyWeight) else { return 100 }
        
        switch selectedGoal {
        case "Muskeln aufbauen":
            return weight * 2.0
        case "Abnehmen":
            return weight * 2.2
        case "Zunehmen":
            return weight * 1.8
        default:
            return weight * 1.6
        }
    }
    
    var body: some View {
        VStack {
            ProgressView(value: Double(currentStep), total: 4)
                .padding()
            
            TabView(selection: $currentStep) {
                welcomeStep
                    .tag(0)
                
                bodyWeightStep
                    .tag(1)
                
                preferencesStep
                    .tag(2)
                
                eatingWindowStep
                    .tag(3)
                
                summaryStep
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            navigationButtons
        }
        .onAppear {
            setupDefaultEatingWindow()
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
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Willkommen bei\nProteinPilot")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Erreiche dein Protein-Ziel ohne lästiges Tracken. Wir passen uns deinem echten Alltag an.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                    Text("Minimaler Aufwand - nur 3-5 Taps pro Tag")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                    Text("Smarte Vorschläge basierend auf deinen Gewohnheiten")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                    Text("Automatische Anpassung bei verpassten Mahlzeiten")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private var bodyWeightStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Deine Daten")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Wir berechnen dein optimales Protein-Ziel basierend auf deinem Gewicht und Ziel.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Körpergewicht")
                        .font(.headline)
                    
                    HStack {
                        TextField("70", text: $bodyWeight)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                isTextFieldFocused = false
                            }
                        
                        Text("kg")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dein Ziel")
                        .font(.headline)
                    
                    Picker("Ziel", selection: $selectedGoal) {
                        ForEach(goals, id: \.self) { goal in
                            Text(goal).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if !bodyWeight.isEmpty, let weight = Double(bodyWeight) {
                    VStack(spacing: 8) {
                        Text("Dein tägliches Protein-Ziel:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(proteinTarget))g")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var preferencesStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Deine Präferenzen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Damit wir dir passende Vorschläge machen können.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Koch-Fähigkeiten")
                        .font(.headline)
                    
                    Picker("Koch-Fähigkeiten", selection: $selectedCookingSkill) {
                        ForEach(cookingSkills, id: \.self) { skill in
                            Text(skill).tag(skill)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Was möchtest du vermeiden?")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100))
                    ], spacing: 8) {
                        ForEach(commonNoGos, id: \.self) { item in
                            Button(action: {
                                if noGos.contains(item) {
                                    noGos.removeAll { $0 == item }
                                } else {
                                    noGos.append(item)
                                }
                            }) {
                                Text(item)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(noGos.contains(item) ? Color.red : Color.gray.opacity(0.2))
                                    .foregroundColor(noGos.contains(item) ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                        
                        Button("Eigene hinzufügen") {
                            showingCustomNoGo = true
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    }
                    
                    if !noGos.isEmpty {
                        Text("Ausgewählt: \(noGos.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingCustomNoGo) {
            NavigationView {
                VStack(spacing: 20) {
                    TextField("z.B. Erdbeeren", text: $customNoGo)
                        .textFieldStyle(.roundedBorder)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Eigene Einschränkung")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Abbrechen") {
                            customNoGo = ""
                            showingCustomNoGo = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Hinzufügen") {
                            if !customNoGo.isEmpty && !noGos.contains(customNoGo) {
                                noGos.append(customNoGo)
                            }
                            customNoGo = ""
                            showingCustomNoGo = false
                        }
                        .disabled(customNoGo.isEmpty)
                    }
                }
            }
        }
    }
    
    private var eatingWindowStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Dein Essensfenster")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Wann isst du normalerweise? Das hilft uns bei smarten Erinnerungen.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Erste Mahlzeit")
                        .font(.headline)
                    
                    DatePicker("", selection: $eatingWindowStart, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Letzte Mahlzeit")
                        .font(.headline)
                    
                    DatePicker("", selection: $eatingWindowEnd, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var summaryStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Alles bereit!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Hier ist deine Zusammenfassung:")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                summaryRow(title: "Tägliches Protein-Ziel", value: "\(Int(proteinTarget))g")
                summaryRow(title: "Ziel", value: selectedGoal)
                summaryRow(title: "Koch-Level", value: selectedCookingSkill)
                summaryRow(title: "Essensfenster", value: "\(eatingWindowStart.formatted(date: .omitted, time: .shortened)) - \(eatingWindowEnd.formatted(date: .omitted, time: .shortened))")
                
                if !noGos.isEmpty {
                    summaryRow(title: "Vermeiden", value: noGos.joined(separator: ", "))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            
            Button("Los geht's! 🚀") {
                setupUser()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(bodyWeight.isEmpty)
            
            Spacer()
        }
        .padding()
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Zurück") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep < 4 {
                Button("Weiter") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
        }
        .padding()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return !bodyWeight.isEmpty && Double(bodyWeight) != nil
        default:
            return true
        }
    }
    
    private func setupDefaultEatingWindow() {
        let calendar = Calendar.current
        let now = Date()
        
        var morning = DateComponents()
        morning.hour = 7
        morning.minute = 0
        eatingWindowStart = calendar.date(from: morning) ?? now
        
        var evening = DateComponents()
        evening.hour = 21
        evening.minute = 0
        eatingWindowEnd = calendar.date(from: evening) ?? now
    }
    
    private func setupUser() {
        guard let weight = Double(bodyWeight) else { 
            print("❌ Invalid body weight: \(bodyWeight)")
            return 
        }
        
        print("🚀 Creating user with target: \(proteinTarget)g")
        dataManager.createUser(
            proteinTarget: proteinTarget,
            eatingStart: eatingWindowStart,
            eatingEnd: eatingWindowEnd,
            bodyWeight: weight
        )
        
        // Force check if user was created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let user = dataManager.getCurrentUser() {
                print("✅ User created successfully: \(user.proteinDailyTarget)g target")
            } else {
                print("❌ User creation failed")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(DataManager.shared)
}