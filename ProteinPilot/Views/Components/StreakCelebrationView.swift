import SwiftUI

// MARK: - Streak Celebration Overlay
struct StreakCelebrationView: View {
    let badge: StreakBadge
    let isVisible: Bool
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0
    @State private var animationOpacity: Double = 0
    @State private var confettiOffset: CGFloat = -100
    @State private var badgeRotation: Double = 0
    
    var body: some View {
        if isVisible {
            ZStack {
                // Dark overlay
                Rectangle()
                    .fill(.black.opacity(0.8))
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissCelebration()
                    }
                
                VStack(spacing: 30) {
                    // Confetti animation
                    HStack(spacing: 20) {
                        ForEach(0..<8, id: \.self) { index in
                            Text(["🎉", "✨", "💫", "⭐", "🌟", "💥", "🎊", "🔥"][index])
                                .font(.title)
                                .offset(y: confettiOffset)
                                .animation(
                                    .interpolatingSpring(stiffness: 100, damping: 8)
                                    .delay(Double(index) * 0.1),
                                    value: confettiOffset
                                )
                        }
                    }
                    
                    // Main badge celebration
                    VStack(spacing: 20) {
                        // Badge icon with pulse animation
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .scaleEffect(animationScale)
                            
                            Text(badge.emoji)
                                .font(.system(size: 60))
                                .scaleEffect(animationScale)
                                .rotationEffect(.degrees(badgeRotation))
                        }
                        
                        // Title and message
                        VStack(spacing: 12) {
                            Text("Streak Achievement!")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(badge.title)
                                .font(.system(.title, design: .rounded, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.84, blue: 0.0),
                                            Color(red: 1.0, green: 0.65, blue: 0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(badge.celebrationMessage)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Continue button
                        Button(action: dismissCelebration) {
                            HStack {
                                Text("Weiter so!")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0),
                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .scaleEffect(animationScale)
                    }
                    .opacity(animationOpacity)
                    
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                startCelebrationAnimation()
            }
        }
    }
    
    private func startCelebrationAnimation() {
        // Confetti first
        withAnimation(.easeOut(duration: 0.8)) {
            confettiOffset = 100
        }
        
        // Main content with delay
        withAnimation(.interpolatingSpring(stiffness: 150, damping: 12).delay(0.2)) {
            animationScale = 1.0
            animationOpacity = 1.0
        }
        
        // Badge rotation
        withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
            badgeRotation = 360
        }
        
        // Auto-dismiss after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if isVisible {
                dismissCelebration()
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOpacity = 0
            animationScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Daily Achievement Toast
struct DailyAchievementToast: View {
    let achievement: DailyAchievement
    let isVisible: Bool
    let onDismiss: () -> Void
    
    @State private var slideOffset: CGFloat = -100
    @State private var toastOpacity: Double = 0
    
    var body: some View {
        if isVisible {
            VStack {
                HStack(spacing: 12) {
                    Text(achievement.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievement.title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(achievement.message)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.8),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                                            Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 60) // Below status bar
            .offset(y: slideOffset)
            .opacity(toastOpacity)
            .onAppear {
                showToast()
            }
            .onTapGesture {
                onDismiss()
            }
        }
    }
    
    private func showToast() {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
            slideOffset = 0
            toastOpacity = 1
        }
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hideToast()
        }
    }
    
    private func hideToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            slideOffset = -100
            toastOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        VStack {
            Text("Background Content")
                .foregroundColor(.white)
        }
        
        StreakCelebrationView(
            badge: .oneWeek,
            isVisible: true,
            onDismiss: { print("Celebration dismissed") }
        )
    }
}