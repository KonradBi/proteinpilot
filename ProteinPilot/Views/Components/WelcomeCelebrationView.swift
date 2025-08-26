import SwiftUI

// MARK: - Welcome Celebration for First-Time Users
struct WelcomeCelebrationView: View {
    let isVisible: Bool
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0
    @State private var animationOpacity: Double = 0
    @State private var confettiOffset: CGFloat = -100
    @State private var welcomeTextOffset: CGFloat = 50
    @State private var buttonScale: CGFloat = 0
    
    var body: some View {
        if isVisible {
            ZStack {
                // Dark overlay with gradient
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.9),
                                Color.black.opacity(0.95)
                            ],
                            center: .center,
                            startRadius: 100,
                            endRadius: 500
                        )
                    )
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Confetti explosion
                    HStack(spacing: 15) {
                        ForEach(0..<12, id: \.self) { index in
                            Text(["🎉", "✨", "💫", "⭐", "🌟", "💥", "🎊", "🔥", "🚀", "💪", "🏆", "👑"][index])
                                .font(.system(size: 24))
                                .offset(y: confettiOffset)
                                .rotationEffect(.degrees(Double.random(in: -30...30)))
                                .animation(
                                    .interpolatingSpring(stiffness: 120, damping: 8)
                                    .delay(Double(index) * 0.05),
                                    value: confettiOffset
                                )
                        }
                    }
                    
                    // Main welcome content
                    VStack(spacing: 30) {
                        // Welcome emoji with scale animation
                        Text("🎉")
                            .font(.system(size: 80))
                            .scaleEffect(animationScale)
                            .animation(.interpolatingSpring(stiffness: 100, damping: 6).delay(0.5), value: animationScale)
                        
                        // Welcome text with slide-up animation
                        VStack(spacing: 16) {
                            Text("Willkommen bei")
                                .font(.system(.title2, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .offset(y: welcomeTextOffset)
                            
                            Text("ProteinPilot")
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.84, blue: 0.0),
                                            Color(red: 1.0, green: 0.65, blue: 0.0),
                                            Color(red: 0.9, green: 0.2, blue: 0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 10, x: 0, y: 5)
                                .offset(y: welcomeTextOffset)
                        }
                        .animation(.interpolatingSpring(stiffness: 150, damping: 20).delay(0.3), value: welcomeTextOffset)
                        
                        // Success message
                        VStack(spacing: 12) {
                            Text("Deine erste Protein-Eingabe!")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Du hast den ersten Schritt zu deinem Protein-Ziel gemacht. Jeden Eintrag bringt dich näher zu deinem Ziel!")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .opacity(animationOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(0.8), value: animationOpacity)
                        
                        // Fun facts about protein tracking
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Text("💪")
                                    .font(.title2)
                                Text("Jede Eingabe = Ein Schritt zum Ziel")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Text("🔥")
                                    .font(.title2)
                                Text("Streaks motivieren dich täglich")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Text("🎯")
                                    .font(.title2)
                                Text("Kleine Belohnungen bei jedem Fortschritt")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(animationOpacity)
                        .animation(.easeInOut(duration: 0.8).delay(1.0), value: animationOpacity)
                        
                        // Continue button
                        Button(action: dismissWelcome) {
                            HStack(spacing: 12) {
                                Text("Let's Go! 🚀")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
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
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 15, x: 0, y: 8)
                            .scaleEffect(buttonScale)
                        }
                        .animation(.interpolatingSpring(stiffness: 200, damping: 15).delay(1.2), value: buttonScale)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                startWelcomeAnimation()
            }
        }
    }
    
    private func startWelcomeAnimation() {
        // Confetti explosion first
        withAnimation(.easeOut(duration: 1.2)) {
            confettiOffset = 100
        }
        
        // Welcome emoji scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationScale = 1.0
        }
        
        // Text slide up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            welcomeTextOffset = 0
        }
        
        // Content fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            animationOpacity = 1.0
        }
        
        // Button scale in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            buttonScale = 1.0
        }
        
        // Auto-dismiss after 8 seconds if user doesn't interact
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            if isVisible {
                dismissWelcome()
            }
        }
    }
    
    private func dismissWelcome() {
        withAnimation(.easeInOut(duration: 0.4)) {
            animationOpacity = 0
            animationScale = 0.8
            buttonScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

// MARK: - Mini Achievement Celebration (for progress milestones)
struct MiniAchievementCelebration: View {
    let achievement: DailyAchievement
    let isVisible: Bool
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var sparkleRotation: Double = 0
    
    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                
                // Mini celebration card
                HStack(spacing: 12) {
                    // Achievement emoji with sparkle animation
                    ZStack {
                        Text("✨")
                            .font(.title3)
                            .rotationEffect(.degrees(sparkleRotation))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: sparkleRotation)
                        
                        Text(achievement.emoji)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Weiter so! 💪")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9),
                                    Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(scale)
                .opacity(opacity)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Above tab bar
            .onAppear {
                showMiniCelebration()
            }
            .onTapGesture {
                onDismiss()
            }
        }
    }
    
    private func showMiniCelebration() {
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Start sparkle rotation
        sparkleRotation = 360
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            hideMiniCelebration()
        }
    }
    
    private func hideMiniCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        WelcomeCelebrationView(
            isVisible: true,
            onDismiss: { print("Welcome dismissed") }
        )
    }
}