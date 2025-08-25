import Foundation
import EventKit

class CalendarService: ObservableObject {
    static let shared = CalendarService()
    private let eventStore = EKEventStore()
    
    @Published var hasCalendarAccess = false
    @Published var upcomingEvents: [EKEvent] = []
    
    private init() {
        checkCalendarAccess()
    }
    
    func requestCalendarAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            DispatchQueue.main.async {
                self.hasCalendarAccess = granted
            }
        } catch {
            print("Calendar access error: \(error)")
        }
    }
    
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = (status == .fullAccess)
    }
    
    func getUpcomingEvents(for date: Date = Date()) {
        guard hasCalendarAccess else { return }
        
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? date
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        DispatchQueue.main.async {
            self.upcomingEvents = events
        }
    }
    
    func analyzeScheduleForMealTiming() -> ScheduleAnalysis {
        let now = Date()
        let calendar = Calendar.current
        
        // Finde den nächsten freien Zeitblock
        let nextFreeSlot = findNextFreeTimeSlot(from: now, durationMinutes: 15)
        
        // Analysiere Stress-Level basierend auf Event-Dichte
        let stressLevel = calculateStressLevel(for: now)
        
        // Bestimme verfügbare Zeit für Mahlzeiten
        let availableTime = calculateAvailableTimeForMeals(from: now)
        
        return ScheduleAnalysis(
            nextFreeSlot: nextFreeSlot,
            stressLevel: stressLevel,
            availableTime: availableTime,
            timeOfDay: getTimeOfDay(for: now)
        )
    }
    
    private func findNextFreeTimeSlot(from startTime: Date, durationMinutes: Int) -> Date? {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: startTime) ?? startTime
        
        var currentTime = startTime
        let slotDuration = TimeInterval(durationMinutes * 60)
        
        while currentTime < endOfDay {
            let slotEnd = currentTime.addingTimeInterval(slotDuration)
            
            let hasConflict = upcomingEvents.contains { event in
                let eventStart = event.startDate ?? Date()
                let eventEnd = event.endDate ?? Date()
                
                return (currentTime < eventEnd && slotEnd > eventStart)
            }
            
            if !hasConflict {
                return currentTime
            }
            
            // Versuche nächsten 15-Minuten-Slot
            currentTime = currentTime.addingTimeInterval(15 * 60)
        }
        
        return nil
    }
    
    private func calculateStressLevel(for date: Date) -> StressLevel {
        let calendar = Calendar.current
        let hourStart = calendar.date(byAdding: .hour, value: -1, to: date) ?? date
        let hourEnd = calendar.date(byAdding: .hour, value: 1, to: date) ?? date
        
        let eventsInRange = upcomingEvents.filter { event in
            guard let start = event.startDate, let end = event.endDate else { return false }
            return (start < hourEnd && end > hourStart)
        }
        
        let meetingCount = eventsInRange.count
        let backToBackMeetings = countBackToBackMeetings()
        
        if meetingCount >= 3 || backToBackMeetings >= 2 {
            return .high
        } else if meetingCount >= 1 || backToBackMeetings >= 1 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func countBackToBackMeetings() -> Int {
        var count = 0
        let sortedEvents = upcomingEvents.sorted { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }
        
        for i in 0..<(sortedEvents.count - 1) {
            let currentEnd = sortedEvents[i].endDate ?? Date()
            let nextStart = sortedEvents[i + 1].startDate ?? Date()
            
            // Weniger als 15 Minuten Pause = back-to-back
            if nextStart.timeIntervalSince(currentEnd) < 15 * 60 {
                count += 1
            }
        }
        
        return count
    }
    
    private func calculateAvailableTimeForMeals(from startTime: Date) -> Int {
        guard let nextMeeting = upcomingEvents.first(where: { 
            ($0.startDate ?? Date()) > startTime 
        }) else {
            return 60 // Mindestens 1 Stunde wenn kein Meeting
        }
        
        let timeUntilMeeting = (nextMeeting.startDate ?? Date()).timeIntervalSince(startTime)
        return Int(timeUntilMeeting / 60) // Minuten
    }
    
    private func getTimeOfDay(for date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        
        switch hour {
        case 6..<11:
            return .morning
        case 11..<14:
            return .lunch
        case 14..<18:
            return .afternoon
        case 18..<22:
            return .evening
        default:
            return .night
        }
    }
}

// MARK: - Data Models

struct ScheduleAnalysis {
    let nextFreeSlot: Date?
    let stressLevel: StressLevel
    let availableTime: Int // Minuten
    let timeOfDay: TimeOfDay
    
    var quickMealNeeded: Bool {
        return stressLevel == .high || availableTime < 20
    }
    
    var suggestedPrepTime: Int {
        switch stressLevel {
        case .high:
            return 2 // Nur 2 Minuten
        case .medium:
            return min(10, availableTime / 2)
        case .low:
            return min(30, availableTime - 10)
        }
    }
}

enum StressLevel {
    case low
    case medium
    case high
}

enum TimeOfDay {
    case morning
    case lunch
    case afternoon
    case evening
    case night
    
    var displayName: String {
        switch self {
        case .morning: return "Morgen"
        case .lunch: return "Mittagszeit"
        case .afternoon: return "Nachmittag"
        case .evening: return "Abend"
        case .night: return "Nacht"
        }
    }
}