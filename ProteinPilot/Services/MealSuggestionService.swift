import Foundation

class MealSuggestionService: ObservableObject {
    static let shared = MealSuggestionService()
    
    private init() {}
    
    func getAdaptiveMealSuggestions(
        remainingProtein: Double,
        scheduleAnalysis: ScheduleAnalysis,
        userPreferences: UserPreferences
    ) -> [AdaptiveMealSuggestion] {
        
        let timeContext = analyzeTimeContext(scheduleAnalysis: scheduleAnalysis)
        let suggestions = generateContextualSuggestions(
            remainingProtein: remainingProtein,
            timeContext: timeContext,
            userPreferences: userPreferences
        )
        
        return suggestions.sorted { $0.priority > $1.priority }
    }
    
    private func analyzeTimeContext(scheduleAnalysis: ScheduleAnalysis) -> MealContext {
        let urgency: MealUrgency
        let situation: MealSituation
        
        // Bestimme Dringlichkeit
        switch (scheduleAnalysis.stressLevel, scheduleAnalysis.availableTime) {
        case (.high, _), (_, ..<10):
            urgency = .critical // Sofort essen!
        case (.medium, 10..<30):
            urgency = .urgent // Schnell essen
        default:
            urgency = .normal // Zeit zum Kochen
        }
        
        // Bestimme Situation
        if scheduleAnalysis.quickMealNeeded {
            situation = scheduleAnalysis.availableTime < 5 ? .emergency : .onTheGo
        } else if scheduleAnalysis.timeOfDay == .lunch {
            situation = .office
        } else {
            situation = .home
        }
        
        return MealContext(
            urgency: urgency,
            situation: situation,
            timeOfDay: scheduleAnalysis.timeOfDay,
            availableMinutes: scheduleAnalysis.availableTime
        )
    }
    
    private func generateContextualSuggestions(
        remainingProtein: Double,
        timeContext: MealContext,
        userPreferences: UserPreferences
    ) -> [AdaptiveMealSuggestion] {
        
        var suggestions: [AdaptiveMealSuggestion] = []
        
        // Notfall-Protein (unter 5 Minuten)
        if timeContext.urgency == .critical {
            suggestions.append(contentsOf: getEmergencyProtein(remainingProtein: remainingProtein))
        }
        
        // Schnelle Optionen (5-15 Minuten)
        if timeContext.availableMinutes < 15 {
            suggestions.append(contentsOf: getQuickProtein(
                remainingProtein: remainingProtein,
                timeOfDay: timeContext.timeOfDay
            ))
        }
        
        // Situationsbasierte Vorschläge
        switch timeContext.situation {
        case .emergency:
            suggestions.append(contentsOf: getEmergencyProtein(remainingProtein: remainingProtein))
        case .onTheGo:
            suggestions.append(contentsOf: getPortableProtein(remainingProtein: remainingProtein))
        case .office:
            suggestions.append(contentsOf: getOfficeProtein(
                remainingProtein: remainingProtein,
                timeOfDay: timeContext.timeOfDay
            ))
        case .home:
            suggestions.append(contentsOf: getHomeProtein(
                remainingProtein: remainingProtein,
                timeContext: timeContext,
                cookingSkill: userPreferences.cookingSkill
            ))
        }
        
        // Filtere nach Präferenzen
        suggestions = filterByPreferences(suggestions, userPreferences: userPreferences)
        
        return Array(suggestions.prefix(4)) // Top 4 Vorschläge
    }
    
    private func getEmergencyProtein(remainingProtein: Double) -> [AdaptiveMealSuggestion] {
        let urgentFoods = [
            ("Protein Shake (fertig)", 25.0, 1, "Einfach trinken, sofort verfügbar", MealUrgency.critical),
            ("Hartgekochtes Ei", 6.0, 1, "Schnell geschält und gegessen", MealUrgency.critical),
            ("Griechischer Joghurt Becher", 15.0, 1, "Direkt löffeln, kein Prep nötig", MealUrgency.critical),
            ("Protein Riegel", 20.0, 1, "Auspacken und essen", MealUrgency.urgent),
            ("Milch trinken", 8.0, 1, "Ein Glas, sofort trinkbar", .urgent)
        ]
        
        return urgentFoods.compactMap { (name, protein, time, reason, urgency) in
            guard protein <= remainingProtein + 10 else { return nil }
            return AdaptiveMealSuggestion(
                name: name,
                proteinAmount: protein,
                prepTimeMinutes: time,
                reason: reason,
                context: "🚨 Notfall-Protein",
                priority: urgency == .critical ? 100 : 90,
                urgency: urgency,
                situation: .emergency
            )
        }
    }
    
    private func getQuickProtein(remainingProtein: Double, timeOfDay: TimeOfDay) -> [AdaptiveMealSuggestion] {
        let quickOptions = [
            ("Skyr mit Nüssen", 20.0, 3, "Einfach Nüsse drauf, fertig", MealUrgency.urgent),
            ("Hüttenkäse pur", 14.0, 2, "Direkt aus dem Becher", MealUrgency.urgent),
            ("Thunfisch aus Dose", 25.0, 3, "Dose auf, mit Gabel essen", MealUrgency.urgent),
            ("Protein Smoothie", 30.0, 4, "Schnell mixen und trinken", MealUrgency.normal),
            ("Käse-Würfel", 12.0, 2, "Vorbereitet im Kühlschrank", .urgent)
        ]
        
        let contextSuffix = timeOfDay == .morning ? "zum Frühstück" : 
                           timeOfDay == .lunch ? "für zwischendurch" : "als Snack"
        
        return quickOptions.compactMap { (name, protein, time, reason, urgency) in
            guard protein <= remainingProtein + 10 else { return nil }
            return AdaptiveMealSuggestion(
                name: name,
                proteinAmount: protein,
                prepTimeMinutes: time,
                reason: reason,
                context: "⚡ Schnell \(contextSuffix)",
                priority: 80,
                urgency: urgency,
                situation: .onTheGo
            )
        }
    }
    
    private func getPortableProtein(remainingProtein: Double) -> [AdaptiveMealSuggestion] {
        let portableOptions = [
            ("Protein Shake to-go", 25.0, 3, "Shaker mitnehmen", MealUrgency.normal),
            ("Nuss-Mix Tüte", 8.0, 1, "Perfekt für unterwegs", MealUrgency.normal),
            ("Beef Jerky", 15.0, 1, "Lange haltbar, kein Kühlen nötig", MealUrgency.normal),
            ("Protein Riegel Premium", 22.0, 1, "Hochwertig und sättigend", MealUrgency.normal),
            ("Babybel Käse", 6.0, 1, "Einzeln verpackt", MealUrgency.normal)
        ]
        
        return portableOptions.compactMap { (name, protein, time, reason, urgency) in
            guard protein <= remainingProtein + 10 else { return nil }
            return AdaptiveMealSuggestion(
                name: name,
                proteinAmount: protein,
                prepTimeMinutes: time,
                reason: reason,
                context: "🎒 Für unterwegs",
                priority: 70,
                urgency: urgency,
                situation: .onTheGo
            )
        }
    }
    
    private func getOfficeProtein(remainingProtein: Double, timeOfDay: TimeOfDay) -> [AdaptiveMealSuggestion] {
        let officeOptions = [
            ("Joghurt mit Müsli", 18.0, 5, "Im Büro-Kühlschrank lagern", MealUrgency.normal),
            ("Protein Pudding", 20.0, 2, "Dessert-Feeling im Office", MealUrgency.normal),
            ("Quark mit Beeren", 16.0, 4, "Frisch und erfrischend", MealUrgency.normal),
            ("Protein Coffee", 15.0, 3, "Kaffee + Proteinpulver", MealUrgency.normal),
            ("Hummus mit Ei", 12.0, 5, "Gesund und sättigend", MealUrgency.normal)
        ]
        
        return officeOptions.compactMap { (name, protein, time, reason, urgency) in
            guard protein <= remainingProtein + 10 else { return nil }
            return AdaptiveMealSuggestion(
                name: name,
                proteinAmount: protein,
                prepTimeMinutes: time,
                reason: reason,
                context: "🏢 Büro-tauglich",
                priority: 60,
                urgency: urgency,
                situation: .office
            )
        }
    }
    
    private func getHomeProtein(
        remainingProtein: Double,
        timeContext: MealContext,
        cookingSkill: String
    ) -> [AdaptiveMealSuggestion] {
        let skillLevel = cookingSkill.lowercased()
        var homeOptions: [(String, Double, Int, String, MealUrgency)] = []
        
        // Basis-Optionen für alle
        homeOptions.append(contentsOf: [
            ("Rührei (3 Eier)", 18.0, 8, "Klassisch und lecker", MealUrgency.normal),
            ("Hühnerbrust gebraten", 35.0, 15, "Viel Protein, sehr sättigend", MealUrgency.normal),
            ("Linsen-Salat", 18.0, 12, "Pflanzlich und nahrhaft", MealUrgency.normal)
        ])
        
        // Je nach Kochfähigkeiten
        if skillLevel.contains("fortgeschritten") || skillLevel.contains("profi") {
            homeOptions.append(contentsOf: [
                ("Lachs mit Gemüse", 40.0, 20, "Omega-3 + hochwertiges Protein", MealUrgency.normal),
                ("Quinoa Bowl mit Tofu", 22.0, 25, "Vollwertig und ausgewogen", MealUrgency.normal),
                ("Protein Pancakes", 24.0, 15, "Lecker und proteinreich", MealUrgency.normal)
            ])
        }
        
        return homeOptions.compactMap { (name, protein, time, reason, urgency) in
            guard protein <= remainingProtein + 15 else { return nil }
            return AdaptiveMealSuggestion(
                name: name,
                proteinAmount: protein,
                prepTimeMinutes: time,
                reason: reason,
                context: "🏠 Zuhause kochen",
                priority: 50,
                urgency: urgency,
                situation: .home
            )
        }
    }
    
    private func filterByPreferences(
        _ suggestions: [AdaptiveMealSuggestion], 
        userPreferences: UserPreferences
    ) -> [AdaptiveMealSuggestion] {
        return suggestions.filter { suggestion in
            // Filtere nach No-Gos
            let containsNoGo = userPreferences.noGos.contains { noGo in
                suggestion.name.localizedCaseInsensitiveContains(noGo) ||
                suggestion.reason.localizedCaseInsensitiveContains(noGo)
            }
            return !containsNoGo
        }
    }
}

// MARK: - Data Models

struct AdaptiveMealSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let proteinAmount: Double
    let prepTimeMinutes: Int
    let reason: String
    let context: String
    let priority: Int
    let urgency: MealUrgency
    let situation: MealSituation
    
    var description: String {
        return reason
    }
    
    var urgencyEmoji: String {
        switch urgency {
        case .critical: return "🚨"
        case .urgent: return "⚡"
        case .normal: return "🍽️"
        }
    }
}

struct MealContext {
    let urgency: MealUrgency
    let situation: MealSituation
    let timeOfDay: TimeOfDay
    let availableMinutes: Int
}

enum MealUrgency {
    case critical // <5 Minuten
    case urgent   // 5-15 Minuten
    case normal   // >15 Minuten
}

enum MealSituation {
    case emergency // Absoluter Notfall
    case onTheGo   // Unterwegs
    case office    // Im Büro
    case home      // Zuhause
}