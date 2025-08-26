import Foundation
import SwiftData

// MARK: - Streak System Models
@Model
final class ProteinStreak {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var lastSuccessDate: Date?
    var totalDaysWithGoal: Int = 0
    var streakSaverUsedThisWeek: Bool = false
    var weekStartDate: Date = Calendar.current.startOfWeek(for: Date()) ?? Date()
    
    // Achievements unlocked - stored as comma-separated string
    private var unlockedBadgesString: String = ""
    
    var unlockedBadges: [String] {
        get {
            return unlockedBadgesString.isEmpty ? [] : unlockedBadgesString.components(separatedBy: ",")
        }
        set {
            unlockedBadgesString = newValue.joined(separator: ",")
        }
    }
    
    // Weekly stats
    var thisWeekTargetHits: Int = 0
    var thisWeekTotalDays: Int = 0
    
    // First-time user tracking
    var hasHadFirstEntry: Bool = false
    
    // Daily achievements - stored as comma-separated string, reset daily
    private var todaysDailyAchievementsString: String = ""
    
    var todaysDailyAchievements: [String] {
        get {
            return todaysDailyAchievementsString.isEmpty ? [] : todaysDailyAchievementsString.components(separatedBy: ",")
        }
        set {
            todaysDailyAchievementsString = newValue.joined(separator: ",")
        }
    }
    
    init() {
        self.currentStreak = 0
        self.bestStreak = 0
        self.lastSuccessDate = nil
        self.totalDaysWithGoal = 0
        self.streakSaverUsedThisWeek = false
        self.weekStartDate = Calendar.current.startOfWeek(for: Date()) ?? Date()
        self.unlockedBadgesString = ""
        self.thisWeekTargetHits = 0
        self.thisWeekTotalDays = 0
        self.hasHadFirstEntry = false
        self.todaysDailyAchievementsString = ""
    }
}

// MARK: - Streak Badge System
enum StreakBadge: String, CaseIterable {
    case firstDay = "first_day"
    case threeDays = "three_days" 
    case oneWeek = "one_week"
    case twoWeeks = "two_weeks"
    case oneMonth = "one_month"
    case threeMonths = "three_months"
    case proteinPro = "protein_pro"
    case consistencyKing = "consistency_king"
    
    var title: String {
        switch self {
        case .firstDay: return "Starter"
        case .threeDays: return "Getting Started"
        case .oneWeek: return "Week Warrior"
        case .twoWeeks: return "Fortnight Fighter"
        case .oneMonth: return "Monthly Master"
        case .threeMonths: return "Protein Pro"
        case .proteinPro: return "Legendary"
        case .consistencyKing: return "Consistency King"
        }
    }
    
    var emoji: String {
        switch self {
        case .firstDay: return "⚡"
        case .threeDays: return "🔥"
        case .oneWeek: return "💪"
        case .twoWeeks: return "🏆"
        case .oneMonth: return "👑"
        case .threeMonths: return "🚀"
        case .proteinPro: return "💎"
        case .consistencyKing: return "🌟"
        }
    }
    
    var requiredDays: Int {
        switch self {
        case .firstDay: return 1
        case .threeDays: return 3
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .proteinPro: return 180
        case .consistencyKing: return 365
        }
    }
    
    var celebrationMessage: String {
        switch self {
        case .firstDay: return "Erster Tag geschafft! Der Anfang ist gemacht! ⚡"
        case .threeDays: return "3 Tage in Folge! Du bist on fire! 🔥"
        case .oneWeek: return "Eine ganze Woche! Das wird zur Gewohnheit! 💪"
        case .twoWeeks: return "14 Tage Streak! Du bist ein Protein-Champion! 🏆"
        case .oneMonth: return "30 Tage! Das ist schon eine echte Lifestyle-Änderung! 👑"
        case .threeMonths: return "90 Tage Streak! Du bist ein Protein-Pro! 🚀"
        case .proteinPro: return "180 Tage! Du lebst den Protein-Lifestyle! 💎"
        case .consistencyKing: return "365 Tage! Du bist der Consistency King! 🌟"
        }
    }
}

// MARK: - Daily Micro-Achievements  
enum DailyAchievement: String, CaseIterable {
    // INSTANT REWARDS (sofort bei jeder Eingabe)
    case firstEntry = "first_entry"        // Allererste Protein-Eingabe überhaupt
    case dailyStart = "daily_start"        // Erste Eingabe des Tages
    case goodProgress = "good_progress"    // 25%+ des Tagesziels erreicht
    case halfwayThere = "halfway_there"    // 50%+ des Tagesziels erreicht
    case almostThere = "almost_there"      // 75%+ des Tagesziels erreicht
    case goalReached = "goal_reached"      // 100% des Tagesziels erreicht
    
    // TIME-BASED REWARDS
    case earlyBird = "early_bird"          // Protein vor 9 Uhr
    case midnightWarrior = "midnight_warrior" // Nach 22 Uhr noch eingegeben
    case weekendWarrior = "weekend_warrior" // Samstag/Sonntag
    
    // BEHAVIOR REWARDS
    case perfectDay = "perfect_day"         // Exakt Ziel getroffen
    case powerDay = "power_day"            // 150%+ vom Ziel  
    case comebackKid = "comeback_kid"      // Nach Streak-Break wieder angefangen
    case newRecipe = "new_recipe"          // Neues Rezept ausprobiert
    case variety = "variety"               // 5+ verschiedene Protein-Quellen
    
    var title: String {
        switch self {
        // Instant rewards
        case .firstEntry: return "Welcome!"
        case .dailyStart: return "Daily Start"
        case .goodProgress: return "Good Progress"
        case .halfwayThere: return "Halfway There"
        case .almostThere: return "Almost There"
        case .goalReached: return "Goal Reached!"
        
        // Time-based
        case .earlyBird: return "Early Bird"
        case .midnightWarrior: return "Midnight Warrior"
        case .weekendWarrior: return "Weekend Warrior"
        
        // Behavior
        case .perfectDay: return "Bullseye"
        case .powerDay: return "Power Day" 
        case .comebackKid: return "Comeback Kid"
        case .newRecipe: return "Recipe Explorer"
        case .variety: return "Protein Variety"
        }
    }
    
    var emoji: String {
        switch self {
        // Instant rewards
        case .firstEntry: return "🎉"
        case .dailyStart: return "🌟"
        case .goodProgress: return "📈"
        case .halfwayThere: return "🎯"
        case .almostThere: return "🔥"
        case .goalReached: return "✅"
        
        // Time-based
        case .earlyBird: return "🌅"
        case .midnightWarrior: return "🌙"
        case .weekendWarrior: return "🎉"
        
        // Behavior
        case .perfectDay: return "🎯"
        case .powerDay: return "⚡"
        case .comebackKid: return "💪"
        case .newRecipe: return "🔍"
        case .variety: return "🌈"
        }
    }
    
    var message: String {
        switch self {
        // Instant rewards
        case .firstEntry: return "Willkommen bei ProteinPilot! Deine erste Eingabe ist der Start!"
        case .dailyStart: return "Perfekt! Du hast heute schon angefangen!"
        case .goodProgress: return "25% geschafft - du bist auf dem richtigen Weg!"
        case .halfwayThere: return "Halbzeit! Du schaffst das heute easy!"
        case .almostThere: return "75% geschafft - nur noch ein kleiner Push!"
        case .goalReached: return "Tagesziel erreicht! Du rockst das! 🚀"
        
        // Time-based
        case .earlyBird: return "Protein vor 9 Uhr - du startest stark in den Tag!"
        case .midnightWarrior: return "Auch spät am Abend noch fleißig - Respekt!"
        case .weekendWarrior: return "Auch am Wochenende durchgezogen - Respekt!"
        
        // Behavior
        case .perfectDay: return "Exakt dein Ziel getroffen - perfekte Balance!"
        case .powerDay: return "Über 150% geschafft - du bist heute on fire!"
        case .comebackKid: return "Zurück im Game! Streak neu gestartet!"
        case .newRecipe: return "Neues Rezept ausprobiert - Abwechslung ist key!"
        case .variety: return "5+ Protein-Quellen heute - super Vielfalt!"
        }
    }
}

// MARK: - Streak Calculation Logic
extension ProteinStreak {
    
    /// Check if today qualifies for streak continuation
    func updateStreak(todayHitTarget: Bool, todaysProtein: Double, targetProtein: Double) -> [StreakBadge] {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        var newBadges: [StreakBadge] = []
        
        // Check if we need to reset week stats
        let currentWeekStart = Calendar.current.startOfWeek(for: Date()) ?? Date()
        if currentWeekStart != weekStartDate {
            streakSaverUsedThisWeek = false
            weekStartDate = currentWeekStart
            thisWeekTargetHits = 0
            thisWeekTotalDays = 0
        }
        
        // Update week stats
        thisWeekTotalDays += 1
        if todayHitTarget {
            thisWeekTargetHits += 1
        }
        
        // Streak logic
        if todayHitTarget {
            // Success today
            if let lastSuccess = lastSuccessDate,
               Calendar.current.isDate(lastSuccess, inSameDayAs: yesterday) {
                // Consecutive day - extend streak
                currentStreak += 1
            } else if lastSuccessDate == nil || !Calendar.current.isDate(lastSuccessDate!, inSameDayAs: yesterday) {
                // First day or gap - start new streak
                currentStreak = 1
            }
            
            lastSuccessDate = today
            totalDaysWithGoal += 1
            
            // Update best streak
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            
            // Check for new badges
            newBadges = checkForNewBadges()
            
        } else {
            // Failed today - streak breaks (unless streak saver is used)
            if canUseStreakSaver() {
                // Don't break streak, but mark saver as used
                // User can manually activate this
            } else {
                // Streak breaks
                currentStreak = 0
            }
        }
        
        return newBadges
    }
    
    private func checkForNewBadges() -> [StreakBadge] {
        var newBadges: [StreakBadge] = []
        
        for badge in StreakBadge.allCases {
            if currentStreak >= badge.requiredDays && !unlockedBadges.contains(badge.rawValue) {
                unlockedBadges.append(badge.rawValue)
                newBadges.append(badge)
            }
        }
        
        return newBadges
    }
    
    func canUseStreakSaver() -> Bool {
        return !streakSaverUsedThisWeek && currentStreak >= 3
    }
    
    func useStreakSaver() {
        streakSaverUsedThisWeek = true
    }
    
    // MARK: - Analytics
    var weeklySuccessRate: Double {
        guard thisWeekTotalDays > 0 else { return 0.0 }
        return Double(thisWeekTargetHits) / Double(thisWeekTotalDays)
    }
    
    var isStreakAtRisk: Bool {
        // Check if yesterday was missed and today is in danger
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        if let lastSuccess = lastSuccessDate {
            return !Calendar.current.isDate(lastSuccess, inSameDayAs: yesterday) && currentStreak > 0
        }
        return false
    }
}

// MARK: - Helper Extensions
extension Calendar {
    func startOfWeek(for date: Date) -> Date? {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start
        return startOfWeek
    }
}