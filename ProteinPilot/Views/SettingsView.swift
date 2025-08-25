import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingEditProfile = false
    @State private var notificationsEnabled = true
    @State private var reminderTimes: [Date] = []
    @State private var catchUpEnabled = true
    @State private var catchUpIntensity = 0.3
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                
                targetSection
                
                notificationSection
                
                catchUpSection
                
                dataSection
                
                aboutSection
            }
            .navigationTitle("Einstellungen")
            .onAppear {
                setupDefaultValues()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }
    
    private var profileSection: some View {
        Section("Profil") {
            if let user = dataManager.getCurrentUser() {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gewicht")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(Int(user.bodyWeight))kg")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Tagesziel")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(Int(user.proteinDailyTarget))g")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                
                Button("Profil bearbeiten") {
                    showingEditProfile = true
                }
            }
        }
    }
    
    private var targetSection: some View {
        Section("Ziele") {
            if let user = dataManager.getCurrentUser() {
                HStack {
                    Text("Essensfenster")
                    Spacer()
                    Text("\(user.eatingWindowStart.formatted(date: .omitted, time: .shortened)) - \(user.eatingWindowEnd.formatted(date: .omitted, time: .shortened))")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Ziel")
                    Spacer()
                    Text(user.goal.capitalized)
                        .foregroundColor(.secondary)
                }
                
                if !user.noGos.isEmpty {
                    HStack {
                        Text("Vermeiden")
                        Spacer()
                        Text(user.noGos.joined(separator: ", "))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
    
    private var notificationSection: some View {
        Section("Erinnerungen") {
            Toggle("Benachrichtigungen", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    if newValue {
                        requestNotificationPermission()
                    }
                }
            
            if notificationsEnabled {
                NavigationLink("Erinnerungszeiten") {
                    ReminderTimesView(reminderTimes: $reminderTimes)
                }
                
                HStack {
                    Text("Aktive Erinnerungen")
                    Spacer()
                    Text("\(reminderTimes.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var catchUpSection: some View {
        Section("Catch-up System") {
            Toggle("Flexibler Ausgleich", isOn: $catchUpEnabled)
            
            if catchUpEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ausgleichsintensität")
                        Spacer()
                        Text("\(Int(catchUpIntensity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $catchUpIntensity, in: 0.1...0.5, step: 0.1)
                        .accentColor(.blue)
                }
                
                Text("Bei 30% wird ein Defizit von 20g am nächsten Tag zu 6g Extra-Ziel. Höhere Werte = schnellerer Ausgleich.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var dataSection: some View {
        Section("Daten") {
            NavigationLink("Daten exportieren") {
                DataExportView()
            }
            
            Button("Verlauf löschen") {
                // TODO: Implement history clearing
            }
            .foregroundColor(.orange)
            
            Button("Alle Daten löschen") {
                // TODO: Implement full data reset
            }
            .foregroundColor(.red)
        }
    }
    
    private var aboutSection: some View {
        Section("Über ProteinPilot") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Button("Datenschutz") {
                // TODO: Show privacy policy
            }
            
            Button("Nutzungsbedingungen") {
                // TODO: Show terms of service
            }
            
            Button("Support kontaktieren") {
                // TODO: Open support contact
            }
        }
    }
    
    private func setupDefaultValues() {
        if let user = dataManager.getCurrentUser() {
            // Setup default reminder times based on eating window
            if reminderTimes.isEmpty {
                let calendar = Calendar.current
                let start = user.eatingWindowStart
                let end = user.eatingWindowEnd
                
                // Add reminders at eating window start, middle, and before end
                reminderTimes = [
                    start,
                    calendar.date(byAdding: .hour, value: 4, to: start) ?? start,
                    calendar.date(byAdding: .minute, value: -30, to: end) ?? end
                ]
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    notificationsEnabled = false
                }
            }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var bodyWeight = ""
    @State private var proteinTarget = ""
    @State private var selectedGoal = "Muskeln aufbauen"
    @State private var eatingStart = Date()
    @State private var eatingEnd = Date()
    
    private let goals = ["Muskeln aufbauen", "Gewicht halten", "Abnehmen", "Zunehmen"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Körperdaten") {
                    HStack {
                        Text("Gewicht")
                        Spacer()
                        TextField("70", text: $bodyWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                    }
                    
                    HStack {
                        Text("Tagesziel")
                        Spacer()
                        TextField("100", text: $proteinTarget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                    }
                }
                
                Section("Ziel") {
                    Picker("Ziel", selection: $selectedGoal) {
                        ForEach(goals, id: \.self) { goal in
                            Text(goal).tag(goal)
                        }
                    }
                }
                
                Section("Essensfenster") {
                    DatePicker("Erste Mahlzeit", selection: $eatingStart, displayedComponents: .hourAndMinute)
                    DatePicker("Letzte Mahlzeit", selection: $eatingEnd, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Profil bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }
    
    private func loadCurrentValues() {
        if let user = dataManager.getCurrentUser() {
            bodyWeight = String(Int(user.bodyWeight))
            proteinTarget = String(Int(user.proteinDailyTarget))
            selectedGoal = user.goal
            eatingStart = user.eatingWindowStart
            eatingEnd = user.eatingWindowEnd
        }
    }
    
    private func saveChanges() {
        // TODO: Implement profile update
        dismiss()
    }
}

struct ReminderTimesView: View {
    @Binding var reminderTimes: [Date]
    @State private var newReminderTime = Date()
    @State private var showingAddReminder = false
    
    var body: some View {
        List {
            Section {
                ForEach(reminderTimes.indices, id: \.self) { index in
                    HStack {
                        Text(reminderTimes[index].formatted(date: .omitted, time: .shortened))
                        Spacer()
                        Button("Löschen") {
                            reminderTimes.remove(at: index)
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
            }
            
            Section {
                Button("Neue Erinnerung hinzufügen") {
                    showingAddReminder = true
                }
            }
        }
        .navigationTitle("Erinnerungszeiten")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddReminder) {
            NavigationView {
                VStack {
                    DatePicker("Zeit", selection: $newReminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Neue Erinnerung")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Abbrechen") {
                            showingAddReminder = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Hinzufügen") {
                            reminderTimes.append(newReminderTime)
                            showingAddReminder = false
                        }
                    }
                }
            }
        }
    }
}

struct DataExportView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        List {
            Section("Export Optionen") {
                Button("Als CSV exportieren") {
                    exportAsCSV()
                }
                
                Button("Als JSON exportieren") {
                    exportAsJSON()
                }
            }
            
            Section("Info") {
                Text("Exportierte Daten enthalten deine Protein-Einträge, aber keine persönlichen Identifikationsdaten.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Daten Export")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportAsCSV() {
        // TODO: Implement CSV export
    }
    
    private func exportAsJSON() {
        // TODO: Implement JSON export
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}