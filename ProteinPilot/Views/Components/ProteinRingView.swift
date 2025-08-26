import SwiftUI

struct ProteinRingView: View {
    let currentProtein: Double
    let targetProtein: Double
    let streakData: ProteinStreak?
    let onRingTapped: () -> Void
    
    @State private var animatedDailyProgress: Double = 0
    @State private var animatedLevelProgress: Double = 0
    @State private var levelBadgeScale: CGFloat = 1.0
    
    var progressPercentage: Double {
        guard targetProtein > 0 else { return 0 }
        return min(currentProtein / targetProtein, 1.0)
    }
    
    var remainingProtein: Double {
        max(0, targetProtein - currentProtein)
    }
    
    // MARK: - Level System Calculations
    var currentLevel: ProteinLevel {
        streakData?.currentLevel ?? .rookie
    }
    
    var levelProgress: Double {
        streakData?.progressToNextLevel ?? 0.0
    }
    
    var currentStreak: Int {
        streakData?.currentStreak ?? 0
    }
    
    var daysUntilNextLevel: Int {
        streakData?.daysUntilNextLevel ?? 0
    }
    
    var nextLevel: ProteinLevel? {
        streakData?.nextLevel
    }
    
    // Daily ring colors (inner ring) - matches current level
    var dailyRingColors: [Color] {
        if progressPercentage >= 1.0 {
            // Goal reached - show level colors with extra brightness
            return currentLevel.colors.map { $0.opacity(1.0) }
        } else {
            // In progress - show level colors with reduced opacity
            return currentLevel.colors.map { $0.opacity(0.7) }
        }
    }
    
    // Level ring colors (outer ring) - next level colors
    var levelRingColors: [Color] {
        guard let nextLevel = self.nextLevel else {
            // Max level reached - show current level with gold accent
            let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
            return [currentLevel.colors.first ?? goldColor, goldColor]
        }
        return nextLevel.colors
    }
    
    var body: some View {
        Button(action: onRingTapped) {
            ZStack {
                // MARK: - Level Ring (Outer) - Progress to Next Level
                if true { // Always show level system
                    // Level Background Ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: levelRingColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 10
                        )
                        .frame(width: 290, height: 290)
                    
                    // Level Progress Ring
                    Circle()
                        .trim(from: 0, to: animatedLevelProgress)
                        .stroke(
                            LinearGradient(
                                colors: levelRingColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 290, height: 290)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: levelRingColors.first?.opacity(0.5) ?? .clear, radius: 8, x: 0, y: 0)
                }
                
                // MARK: - Daily Protein Ring (Inner)
                // Background Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: dailyRingColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 18
                    )
                    .frame(width: 240, height: 240)
                
                // Daily Progress Ring
                Circle()
                    .trim(from: 0, to: animatedDailyProgress)
                    .stroke(
                        LinearGradient(
                            colors: dailyRingColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: dailyRingColors.first?.opacity(0.4) ?? .clear, radius: 10, x: 0, y: 0)
                
                // MARK: - Center Content
                VStack(spacing: 4) {
                    // Main protein number with level colors
                    Text("\(Int(currentProtein))")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: dailyRingColors.isEmpty ? [.white] : dailyRingColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // Progress percentage and target
                    HStack(spacing: 6) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundColor(dailyRingColors.first ?? .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder((dailyRingColors.first ?? .white).opacity(0.5), lineWidth: 1)
                                    )
                            )
                        
                        Text("von \(Int(targetProtein))g")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Status message
                    if remainingProtein > 0 {
                        Text("Noch \(Int(remainingProtein))g")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(dailyRingColors.first ?? .green)
                                .font(.caption)
                            Text("Ziel erreicht!")
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((dailyRingColors.first ?? .green).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .strokeBorder((dailyRingColors.first ?? .green).opacity(0.6), lineWidth: 1)
                                )
                        )
                        .padding(.top, 4)
                    }
                }
                
                // MARK: - Level Badge (Positioned at bottom-right of ring)
                // Always show level badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        LevelBadge(level: currentLevel)
                            .scaleEffect(levelBadgeScale)
                            .offset(x: -20, y: -20) // Position at bottom-right
                    }
                }
                
                // MARK: - Level Progress Indicator (Bottom of ring)
                if let nextLevel = self.nextLevel {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 2) {
                                Text("\(daysUntilNextLevel) Tage bis")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(nextLevel.title)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(levelRingColors.first ?? .white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder((levelRingColors.first ?? .white).opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                            .offset(y: -15)
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            // Daily progress animation
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 20).delay(0.2)) {
                animatedDailyProgress = progressPercentage
            }
            // Level progress animation  
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 18).delay(0.4)) {
                animatedLevelProgress = levelProgress
            }
            // Level badge pulse
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
                levelBadgeScale = 1.1
            }
        }
        .onChange(of: progressPercentage) { _, newValue in
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 20)) {
                animatedDailyProgress = newValue
            }
        }
        .onChange(of: levelProgress) { _, newValue in
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 18)) {
                animatedLevelProgress = newValue
            }
        }
        .onChange(of: currentLevel) { _, newLevel in
            // Level up animation - badge bounce
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                levelBadgeScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.interpolatingSpring(stiffness: 200, damping: 12)) {
                    levelBadgeScale = 1.0
                }
            }
        }
    }
}

// MARK: - Color Extension
private extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 40) {
            // Rookie level (1 day streak)
            ProteinRingView(
                currentProtein: 45,
                targetProtein: 120,
                streakData: {
                    let streak = ProteinStreak()
                    streak.currentStreak = 1
                    return streak
                }(),
                onRingTapped: { print("Ring tapped") }
            )
            
            // Dedicated level (14 day streak) - goal reached
            ProteinRingView(
                currentProtein: 125,
                targetProtein: 120,
                streakData: {
                    let streak = ProteinStreak()
                    streak.currentStreak = 14
                    return streak
                }(),
                onRingTapped: { print("Ring tapped") }
            )
            
            // Master level (180 day streak)
            ProteinRingView(
                currentProtein: 90,
                targetProtein: 120,
                streakData: {
                    let streak = ProteinStreak()
                    streak.currentStreak = 180
                    return streak
                }(),
                onRingTapped: { print("Ring tapped") }
            )
        }
    }
}