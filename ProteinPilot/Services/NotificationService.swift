import Foundation
import UserNotifications
import EventKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func scheduleProteinReminder(
        at time: Date,
        remainingProtein: Double,
        identifier: String = UUID().uuidString
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Protein Erinnerung 🍽️"
        
        if remainingProtein > 0 {
            content.body = "Du brauchst noch \(Int(remainingProtein))g Protein heute!"
            content.categoryIdentifier = "PROTEIN_REMINDER"
        } else {
            content.body = "Super! Du hast dein Tagesziel bereits erreicht! 🎉"
            content.categoryIdentifier = "PROTEIN_ACHIEVED"
        }
        
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleSmartReminder(
        for user: User,
        remainingProtein: Double
    ) {
        let now = Date()
        let calendar = Calendar.current
        
        // Get calendar analysis for smart timing
        let calendarService = CalendarService.shared
        let analysis = calendarService.analyzeScheduleForMealTiming()
        
        // Only schedule if we're within eating window
        let startComponents = calendar.dateComponents([.hour, .minute], from: user.eatingWindowStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: user.eatingWindowEnd)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute,
              let nowHour = nowComponents.hour,
              let nowMinute = nowComponents.minute else { return }
        
        let startMinutesFromMidnight = startHour * 60 + startMinute
        let endMinutesFromMidnight = endHour * 60 + endMinute
        let nowMinutesFromMidnight = nowHour * 60 + nowMinute
        
        // Check if current time is within eating window
        let isWithinWindow = nowMinutesFromMidnight >= startMinutesFromMidnight &&
                           nowMinutesFromMidnight <= endMinutesFromMidnight
        
        // Calculate time until eating window ends
        let timeUntilWindowEnd = TimeInterval((endMinutesFromMidnight - nowMinutesFromMidnight) * 60)
        
        if isWithinWindow && remainingProtein > 10 {
            // Smart scheduling based on calendar and remaining time
            let reminders = calculateSmartReminderTimes(
                remainingProtein: remainingProtein,
                timeUntilWindowEnd: timeUntilWindowEnd,
                calendarAnalysis: analysis,
                user: user
            )
            
            for (index, reminderTime) in reminders.enumerated() {
                let suggestion = generateSmartSuggestion(
                    remainingProtein: remainingProtein,
                    timeLeft: reminderTime.timeIntervalSinceNow,
                    user: user
                )
                
                scheduleContextualProteinReminder(
                    at: reminderTime,
                    remainingProtein: remainingProtein,
                    suggestion: suggestion,
                    identifier: "smart_reminder_\(index)_\(Date().timeIntervalSince1970)"
                )
            }
        }
    }
    
    func setupDailyReminders(for times: [Date]) {
        // Clear existing reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_reminder_1", "daily_reminder_2", "daily_reminder_3"]
        )
        
        for (index, time) in times.enumerated() {
            scheduleProteinReminder(
                at: time,
                remainingProtein: 50, // Placeholder - will be calculated dynamically
                identifier: "daily_reminder_\(index + 1)"
            )
        }
    }
    
    func scheduleEndOfDayReminder(for user: User) {
        let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -30,
            to: user.eatingWindowEnd
        ) ?? user.eatingWindowEnd
        
        scheduleProteinReminder(
            at: reminderTime,
            remainingProtein: 0, // Will be calculated when notification fires
            identifier: "end_of_day_reminder"
        )
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelReminder(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    func setupNotificationActions() async {
        // Legacy actions
        let quickAdd20 = UNNotificationAction(
            identifier: "QUICK_ADD_20",
            title: "20g hinzufügen",
            options: []
        )
        
        let quickAdd30 = UNNotificationAction(
            identifier: "QUICK_ADD_30",
            title: "30g hinzufügen",
            options: []
        )
        
        // Smart contextual actions
        let proteinShake = UNNotificationAction(
            identifier: "PROTEIN_SHAKE",
            title: "🥤 Shake (25g)",
            options: []
        )
        
        let greekYogurt = UNNotificationAction(
            identifier: "GREEK_YOGURT",
            title: "🥛 Joghurt (18g)",
            options: []
        )
        
        let snooze15 = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: "⏰ 15 min später",
            options: []
        )
        
        let openApp = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "App öffnen",
            options: [.foreground]
        )
        
        // Categories for different types of reminders
        let proteinReminderCategory = UNNotificationCategory(
            identifier: "PROTEIN_REMINDER",
            actions: [quickAdd20, quickAdd30, openApp],
            intentIdentifiers: [],
            options: []
        )
        
        let smartReminderCategory = UNNotificationCategory(
            identifier: "SMART_PROTEIN_REMINDER",
            actions: [proteinShake, greekYogurt, snooze15],
            intentIdentifiers: [],
            options: []
        )
        
        let proteinAchievedCategory = UNNotificationCategory(
            identifier: "PROTEIN_ACHIEVED",
            actions: [openApp],
            intentIdentifiers: [],
            options: []
        )
        
        let urgentReminderCategory = UNNotificationCategory(
            identifier: "URGENT_PROTEIN_REMINDER",
            actions: [proteinShake, quickAdd20, openApp],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            proteinReminderCategory,
            smartReminderCategory,
            proteinAchievedCategory,
            urgentReminderCategory
        ])
    }
    
    func handleNotificationAction(_ actionIdentifier: String, completion: @escaping () -> Void) {
        switch actionIdentifier {
        case "QUICK_ADD_20":
            DataManager.shared.addProteinEntry(quantity: 20, proteinGrams: 20)
            scheduleSuccessFollowUp(protein: 20)
            completion()
        case "QUICK_ADD_30":
            DataManager.shared.addProteinEntry(quantity: 30, proteinGrams: 30)
            scheduleSuccessFollowUp(protein: 30)
            completion()
        case "PROTEIN_SHAKE":
            // Add typical protein shake
            DataManager.shared.addProteinEntry(quantity: 30, proteinGrams: 25)
            scheduleSuccessFollowUp(protein: 25)
            completion()
        case "GREEK_YOGURT":
            // Add Greek yogurt portion  
            DataManager.shared.addProteinEntry(quantity: 150, proteinGrams: 18)
            scheduleSuccessFollowUp(protein: 18)
            completion()
        case "SNOOZE_15":
            // Reschedule notification in 15 minutes
            scheduleSnoozeReminder()
            completion()
        default:
            completion()
        }
    }
    
    private func scheduleSuccessFollowUp(protein: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Perfekt! 🎉"
        content.body = "\(Int(protein))g Protein hinzugefügt. Weiter so!"
        content.sound = .default
        content.badge = 0 // Clear badge after success
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "success_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleSnoozeReminder() {
        Task {
            // Get current user and remaining protein
            guard let user = DataManager.shared.getCurrentUser() else { return }
            let currentProtein = DataManager.shared.getTodaysTotalProtein()
            let remainingProtein = max(0, user.proteinDailyTarget - currentProtein)
            
            if remainingProtein > 5 {
                let snoozeTime = Date().addingTimeInterval(15 * 60) // 15 minutes
                let suggestion = generateSmartSuggestion(
                    remainingProtein: remainingProtein,
                    timeLeft: 15 * 60,
                    user: user
                )
                
                scheduleContextualProteinReminder(
                    at: snoozeTime,
                    remainingProtein: remainingProtein,
                    suggestion: suggestion,
                    identifier: "snooze_reminder_\(Date().timeIntervalSince1970)"
                )
            }
        }
    }
    
    // MARK: - Smart Notification Logic
    
    private func calculateSmartReminderTimes(
        remainingProtein: Double,
        timeUntilWindowEnd: TimeInterval,
        calendarAnalysis: ScheduleAnalysis,
        user: User
    ) -> [Date] {
        let now = Date()
        var reminderTimes: [Date] = []
        
        // Critical threshold - less than 90 minutes left
        if timeUntilWindowEnd < 90 * 60 && remainingProtein > 15 {
            // Immediate reminder if free time available
            if let nextFreeSlot = calendarAnalysis.nextFreeSlot, nextFreeSlot <= now.addingTimeInterval(30 * 60) {
                reminderTimes.append(nextFreeSlot)
            } else {
                // Schedule for now if no immediate free slot
                reminderTimes.append(now.addingTimeInterval(5 * 60)) // 5 min delay
            }
            return reminderTimes
        }
        
        // Normal scheduling - find optimal times
        let hoursLeft = timeUntilWindowEnd / 3600
        
        switch hoursLeft {
        case 3...6:
            // Plenty of time - schedule 2 reminders
            reminderTimes.append(now.addingTimeInterval(2 * 60 * 60))      // 2h from now
            reminderTimes.append(now.addingTimeInterval(timeUntilWindowEnd - 60 * 60)) // 1h before window ends
        case 1.5...3:
            // Moderate time - schedule 1 strategic reminder
            reminderTimes.append(now.addingTimeInterval(timeUntilWindowEnd / 2))
        case 0.5...1.5:
            // Limited time - immediate action needed
            reminderTimes.append(now.addingTimeInterval(15 * 60)) // 15 min from now
        default:
            // Less than 30 min - last call
            reminderTimes.append(now.addingTimeInterval(5 * 60))
        }
        
        return reminderTimes
    }
    
    private func generateSmartSuggestion(
        remainingProtein: Double,
        timeLeft: TimeInterval,
        user: User
    ) -> String {
        let hoursLeft = timeLeft / 3600
        
        // Emergency suggestions (< 1 hour left)
        if hoursLeft < 1 {
            if remainingProtein > 25 {
                return "Letzter Call! Protein Shake (25g) = Tagesziel erreicht! 🎯"
            } else if remainingProtein > 15 {
                return "Quick Fix: Griechischer Joghurt (150g) = \(Int(remainingProtein))g Protein ✅"
            } else {
                return "Fast geschafft: Handvoll Nüsse (8g) reicht! 🥜"
            }
        }
        
        // Normal suggestions (1+ hours left)
        if remainingProtein > 30 {
            return "Entspannt Abendessen: Hähnchen/Fisch mit \(Int(remainingProtein))g Protein 🍗"
        } else if remainingProtein > 20 {
            return "Protein Shake (\(Int(remainingProtein))g) oder Quark mit Früchten 🥤"
        } else if remainingProtein > 10 {
            return "Kleine Portion: Eier, Nüsse oder Käse für \(Int(remainingProtein))g 🧀"
        } else {
            return "Fast da! Ein Glas Milch (8g) und du hast es! 🥛"
        }
    }
    
    private func scheduleContextualProteinReminder(
        at time: Date,
        remainingProtein: Double,
        suggestion: String,
        identifier: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Noch \(Int(remainingProtein))g Protein heute 🎯"
        content.body = suggestion
        content.categoryIdentifier = "SMART_PROTEIN_REMINDER"
        content.sound = .default
        content.badge = 1
        
        // Add contextual data for action buttons
        content.userInfo = ["remainingProtein": remainingProtein]
        
        let timeInterval = time.timeIntervalSinceNow
        if timeInterval > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling smart reminder: \(error)")
                }
            }
        }
    }
    
    // MARK: - Adaptive Learning
    
    func scheduleAdaptiveReminder(for user: User) {
        Task {
            let currentProtein = DataManager.shared.getTodaysTotalProtein()
            let remainingProtein = max(0, user.proteinDailyTarget - currentProtein)
            
            guard remainingProtein > 10 else { return }
            
            let optimalTime = await calculateOptimalReminderTime(for: user)
            let suggestion = generateSmartSuggestion(
                remainingProtein: remainingProtein,
                timeLeft: optimalTime.timeIntervalSinceNow,
                user: user
            )
            
            scheduleContextualProteinReminder(
                at: optimalTime,
                remainingProtein: remainingProtein,
                suggestion: suggestion,
                identifier: "adaptive_reminder_\(Date().timeIntervalSince1970)"
            )
        }
    }
    
    private func calculateOptimalReminderTime(for user: User) async -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // Get calendar analysis
        let calendarService = CalendarService.shared
        let analysis = calendarService.analyzeScheduleForMealTiming()
        
        // Check user's historical success patterns
        let preferredTimes = await analyzeUserSuccessPatterns()
        
        // Find optimal time considering:
        // 1. Calendar availability
        // 2. Historical success patterns  
        // 3. Time until eating window ends
        
        if let nextFreeSlot = analysis.nextFreeSlot,
           let preferredHour = preferredTimes.first,
           nextFreeSlot.timeIntervalSinceNow > 0 {
            
            // Try to align with user's preferred success time
            let preferredTime = calendar.date(bySettingHour: preferredHour, minute: 0, second: 0, of: now)
            
            if let preferred = preferredTime,
               preferred > now,
               preferred < user.eatingWindowEnd {
                return preferred
            }
        }
        
        // Fallback: next free slot or 2 hours from now
        return analysis.nextFreeSlot ?? now.addingTimeInterval(2 * 60 * 60)
    }
    
    private func analyzeUserSuccessPatterns() async -> [Int] {
        // Analyze when user typically completes their protein goals
        // This would analyze historical data from DataManager
        let entries = DataManager.shared.getRecentEntries(limit: 100)
        var successTimes: [Int] = []
        
        let calendar = Calendar.current
        let dateGroups = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        // Find days where protein target was reached
        for (_, dayEntries) in dateGroups {
            let totalProtein = dayEntries.reduce(0) { $0 + $1.proteinGrams }
            if totalProtein >= 80 { // Assume target around 100g, 80% success threshold
                // Find the hour of the last meaningful entry
                if let lastEntry = dayEntries.sorted(by: { $0.date < $1.date }).last {
                    let hour = calendar.component(.hour, from: lastEntry.date)
                    successTimes.append(hour)
                }
            }
        }
        
        // Return most common success hours
        let hourCounts = Dictionary(grouping: successTimes) { $0 }
        return hourCounts
            .map { (hour: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .map { $0.hour }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Public API for triggering smart reminders
    
    func triggerSmartReminder() {
        Task {
            guard let user = DataManager.shared.getCurrentUser() else { return }
            let hasPermission = await requestPermission()
            
            if hasPermission {
                await setupNotificationActions()
                scheduleAdaptiveReminder(for: user)
            }
        }
    }
}