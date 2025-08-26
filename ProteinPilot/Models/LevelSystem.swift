import SwiftUI
import Foundation

// MARK: - Level System for Progressive Protein Streaks
enum ProteinLevel: Int, CaseIterable {
    case rookie = 1      // 1 Tag
    case starter = 2     // 3 Tage  
    case consistent = 3  // 7 Tage
    case dedicated = 4   // 14 Tage
    case committed = 5   // 30 Tage
    case advanced = 6    // 60 Tage
    case expert = 7      // 90 Tage
    case master = 8      // 180 Tage
    case legend = 9      // 365 Tage
    case immortal = 10   // 500+ Tage
    
    var title: String {
        switch self {
        case .rookie: return "Rookie"
        case .starter: return "Starter"
        case .consistent: return "Consistent"
        case .dedicated: return "Dedicated"
        case .committed: return "Committed"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        case .master: return "Master"
        case .legend: return "Legend"
        case .immortal: return "Immortal"
        }
    }
    
    var emoji: String {
        switch self {
        case .rookie: return "🥉"
        case .starter: return "🔶"
        case .consistent: return "🥈"
        case .dedicated: return "💎"
        case .committed: return "🥇"
        case .advanced: return "💜"
        case .expert: return "🔮"
        case .master: return "💖"
        case .legend: return "🌈"
        case .immortal: return "👑"
        }
    }
    
    var requiredDays: Int {
        switch self {
        case .rookie: return 1
        case .starter: return 3
        case .consistent: return 7
        case .dedicated: return 14
        case .committed: return 30
        case .advanced: return 60
        case .expert: return 90
        case .master: return 180
        case .legend: return 365
        case .immortal: return 500
        }
    }
    
    var colors: [Color] {
        switch self {
        case .rookie:
            return [
                Color(red: 1.0, green: 0.65, blue: 0.0),   // Orange
                Color(red: 0.9, green: 0.5, blue: 0.1)     // Dark Orange
            ]
        case .starter:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),   // Gold
                Color(red: 0.8, green: 0.65, blue: 0.0)    // Dark Gold
            ]
        case .consistent:
            return [
                Color(red: 0.75, green: 0.75, blue: 0.75), // Silver
                Color(red: 0.9, green: 0.9, blue: 0.9)     // Light Silver
            ]
        case .dedicated:
            return [
                Color(red: 0.4, green: 0.8, blue: 1.0),    // Light Blue
                Color(red: 0.2, green: 0.6, blue: 0.9)     // Blue
            ]
        case .committed:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),   // Pure Gold
                Color(red: 1.0, green: 0.75, blue: 0.0)    // Rich Gold
            ]
        case .advanced:
            return [
                Color(red: 0.6, green: 0.2, blue: 0.8),    // Purple
                Color(red: 0.8, green: 0.4, blue: 1.0)     // Light Purple
            ]
        case .expert:
            return [
                Color(red: 0.2, green: 0.8, blue: 0.8),    // Cyan
                Color(red: 0.4, green: 0.9, blue: 0.9)     // Light Cyan
            ]
        case .master:
            return [
                Color(red: 1.0, green: 0.4, blue: 0.7),    // Pink
                Color(red: 1.0, green: 0.6, blue: 0.8)     // Light Pink
            ]
        case .legend:
            return [
                Color.red, Color.orange, Color.yellow, 
                Color.green, Color.blue, Color.purple
            ] // Rainbow
        case .immortal:
            return [
                Color.black,
                Color(red: 1.0, green: 0.84, blue: 0.0)    // Black Gold
            ]
        }
    }
    
    var shadowColor: Color {
        return colors.first ?? .orange
    }
    
    var celebrationMessage: String {
        switch self {
        case .rookie: return "Willkommen im Game! Dein erster Protein-Tag! 🎉"
        case .starter: return "3 Tage in Folge! Du entwickelst eine Gewohnheit! 🔥"
        case .consistent: return "Eine ganze Woche! Du bist jetzt consistent! 💪"
        case .dedicated: return "2 Wochen! Du bist wirklich dedicated! 🎯"
        case .committed: return "30 Tage! Das ist echtes Commitment! 🥇"
        case .advanced: return "60 Tage! Advanced Protein Warrior! 💜"
        case .expert: return "90 Tage! Du bist ein echter Expert! 🔮"
        case .master: return "180 Tage! Protein Master Level erreicht! 💖"
        case .legend: return "365 Tage! Du bist eine Legend! 🌈"
        case .immortal: return "500+ Tage! Immortal Status unlocked! 👑"
        }
    }
    
    static func levelForStreak(_ streak: Int) -> ProteinLevel {
        for level in ProteinLevel.allCases.reversed() {
            if streak >= level.requiredDays {
                return level
            }
        }
        return .rookie
    }
    
    var nextLevel: ProteinLevel? {
        guard let nextRawValue = ProteinLevel(rawValue: self.rawValue + 1) else {
            return nil
        }
        return nextRawValue
    }
    
    func progressToNextLevel(currentStreak: Int) -> Double {
        guard let nextLevel = self.nextLevel else {
            return 1.0 // Max level reached
        }
        
        let currentLevelDays = self.requiredDays
        let nextLevelDays = nextLevel.requiredDays
        let progressDays = currentStreak - currentLevelDays
        let totalDaysNeeded = nextLevelDays - currentLevelDays
        
        return min(Double(progressDays) / Double(totalDaysNeeded), 1.0)
    }
}

// MARK: - Level System Integration with Streak
extension ProteinStreak {
    var currentLevel: ProteinLevel {
        return ProteinLevel.levelForStreak(currentStreak)
    }
    
    var nextLevel: ProteinLevel? {
        return currentLevel.nextLevel
    }
    
    var progressToNextLevel: Double {
        return currentLevel.progressToNextLevel(currentStreak: currentStreak)
    }
    
    var daysUntilNextLevel: Int {
        guard let nextLevel = self.nextLevel else { return 0 }
        return max(0, nextLevel.requiredDays - currentStreak)
    }
    
    // Check if user leveled up today
    func checkForLevelUp() -> ProteinLevel? {
        let previousLevel = ProteinLevel.levelForStreak(max(0, currentStreak - 1))
        let currentLevel = ProteinLevel.levelForStreak(currentStreak)
        
        if currentLevel.rawValue > previousLevel.rawValue {
            return currentLevel
        }
        return nil
    }
}

// MARK: - Level Badge View Component
struct LevelBadge: View {
    let level: ProteinLevel
    var size: CGFloat = 44
    
    init(level: ProteinLevel, size: CGFloat = 44) {
        self.level = level
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Badge background with level colors
            Circle()
                .fill(
                    RadialGradient(
                        colors: level.colors.count > 2 ? 
                            [level.colors[0], level.colors[1]] : level.colors,
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: level.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: level.shadowColor.opacity(0.5), radius: 6, x: 0, y: 3)
            
            // Level number or emoji
            if level == .legend {
                // Rainbow effect for legend
                Text(level.emoji)
                    .font(.system(size: 20, weight: .bold))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            } else {
                VStack(spacing: 0) {
                    Text("\(level.rawValue)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    
                    if level.rawValue >= 5 {
                        Text(level.emoji)
                            .font(.system(size: 8))
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            ForEach([ProteinLevel.rookie, .starter, .consistent, .dedicated, .committed], id: \.rawValue) { level in
                VStack {
                    LevelBadge(level: level)
                    Text(level.title)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        
        HStack(spacing: 16) {
            ForEach([ProteinLevel.advanced, .expert, .master, .legend, .immortal], id: \.rawValue) { level in
                VStack {
                    LevelBadge(level: level)
                    Text(level.title)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
    .padding()
    .background(Color.black)
}