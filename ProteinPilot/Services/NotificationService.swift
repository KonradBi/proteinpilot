import Foundation
import UserNotifications

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
        
        if isWithinWindow && remainingProtein > 20 {
            // Schedule a reminder in 2 hours if we still need significant protein
            let reminderTime = calendar.date(byAdding: .hour, value: 2, to: now) ?? now
            
            scheduleProteinReminder(
                at: reminderTime,
                remainingProtein: remainingProtein,
                identifier: "smart_reminder_\(Date().timeIntervalSince1970)"
            )
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
        
        let openApp = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "App öffnen",
            options: [.foreground]
        )
        
        let proteinReminderCategory = UNNotificationCategory(
            identifier: "PROTEIN_REMINDER",
            actions: [quickAdd20, quickAdd30, openApp],
            intentIdentifiers: [],
            options: []
        )
        
        let proteinAchievedCategory = UNNotificationCategory(
            identifier: "PROTEIN_ACHIEVED",
            actions: [openApp],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            proteinReminderCategory,
            proteinAchievedCategory
        ])
    }
    
    func handleNotificationAction(_ actionIdentifier: String, completion: @escaping () -> Void) {
        switch actionIdentifier {
        case "QUICK_ADD_20":
            DataManager.shared.addProteinEntry(quantity: 20, proteinGrams: 20)
            completion()
        case "QUICK_ADD_30":
            DataManager.shared.addProteinEntry(quantity: 30, proteinGrams: 30)
            completion()
        default:
            completion()
        }
    }
}