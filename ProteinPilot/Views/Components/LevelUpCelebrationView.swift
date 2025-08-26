import SwiftUI

// MARK: - Level Up Celebration
struct LevelUpCelebrationView: View {
    let newLevel: ProteinLevel
    let isVisible: Bool
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0
    @State private var animationOpacity: Double = 0
    @State private var confettiOffset: CGFloat = -100
    @State private var levelBadgeRotation: Double = 0
    @State private var levelBadgeScale: CGFloat = 0
    @State private var glowRadius: CGFloat = 0
    @State private var ringExplosion: Bool = false
    
    var body: some View {
        if isVisible {
            ZStack {
                // Dynamic gradient background based on level
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                newLevel.colors.first?.opacity(0.3) ?? Color.black.opacity(0.3),
                                Color.black.opacity(0.95)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 400
                        )
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: isVisible)
                
                VStack(spacing: 40) {
                    // Level-specific confetti explosion
                    levelConfetti
                    
                    // Main level celebration content
                    VStack(spacing: 30) {
                        // Level badge with dramatic animation
                        ZStack {
                            // Expanding rings effect
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: newLevel.colors.map { $0.opacity(0.3) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                                    .scaleEffect(ringExplosion ? 2.0 : 1.0)
                                    .opacity(ringExplosion ? 0.0 : 0.8)
                                    .animation(
                                        .easeOut(duration: 1.5).delay(Double(index) * 0.2),
                                        value: ringExplosion
                                    )
                            }
                            
                            // Main level badge
                            LevelBadge(level: newLevel, size: 80)
                                .scaleEffect(levelBadgeScale)
                                .rotationEffect(.degrees(levelBadgeRotation))
                                .shadow(color: newLevel.shadowColor.opacity(0.8), radius: glowRadius, x: 0, y: 0)
                        }
                        
                        // Level title and message
                        VStack(spacing: 16) {
                            Text("LEVEL UP!")
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .foregroundColor(.white)
                                .opacity(animationOpacity)
                            
                            HStack(spacing: 8) {
                                Text("Level \(newLevel.rawValue)")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: newLevel.colors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text(newLevel.title)
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .opacity(animationOpacity)
                            
                            Text(newLevel.celebrationMessage)
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .opacity(animationOpacity)
                        }
                        
                        // Special effects based on level
                        levelSpecialEffects
                        
                        // Continue button with level colors
                        Button(action: dismissCelebration) {
                            HStack(spacing: 10) {
                                Text("Awesome! 🚀")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: newLevel.colors.count >= 2 ? 
                                        Array(newLevel.colors.prefix(2)) : newLevel.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: newLevel.shadowColor.opacity(0.6), radius: 12, x: 0, y: 6)
                            .scaleEffect(animationScale)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .onAppear {
                startLevelUpAnimation()
            }
        }
    }
    
    // MARK: - Level-Specific Confetti
    @ViewBuilder
    private var levelConfetti: some View {
        HStack(spacing: 12) {
            ForEach(0..<15, id: \.self) { index in
                let confettiEmojis = getConfettiEmojis(for: newLevel)
                Text(confettiEmojis[index % confettiEmojis.count])
                    .font(.system(size: 20 + CGFloat(index % 3) * 4))
                    .offset(y: confettiOffset)
                    .rotationEffect(.degrees(Double.random(in: -45...45)))
                    .animation(
                        .interpolatingSpring(stiffness: 80 + Double(index * 10), damping: 8)
                        .delay(Double(index) * 0.03),
                        value: confettiOffset
                    )
            }
        }
    }
    
    // MARK: - Level-Specific Special Effects
    @ViewBuilder
    private var levelSpecialEffects: some View {
        switch newLevel {
        case .legend:
            // Rainbow sparks for legend level
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(newLevel.colors[index % newLevel.colors.count])
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1).repeatCount(3), value: animationScale)
                }
            }
            
        case .immortal:
            // Crown sparkles for immortal level
            HStack(spacing: 15) {
                Text("👑")
                    .font(.title)
                    .scaleEffect(animationScale)
                Text("IMMORTAL")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .scaleEffect(animationScale)
                Text("👑")
                    .font(.title)
                    .scaleEffect(animationScale)
            }
            
        case .master:
            // Diamond sparkles
            HStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { _ in
                    Text("💎")
                        .font(.title2)
                        .scaleEffect(animationScale)
                        .animation(.easeInOut(duration: 0.6).repeatCount(2), value: animationScale)
                }
            }
            
        default:
            // Default sparkle effect
            HStack(spacing: 12) {
                Text("✨")
                    .font(.title2)
                    .scaleEffect(animationScale)
                Text(newLevel.emoji)
                    .font(.largeTitle)
                    .scaleEffect(animationScale)
                Text("✨")
                    .font(.title2)
                    .scaleEffect(animationScale)
            }
        }
    }
    
    // MARK: - Animation Logic
    private func startLevelUpAnimation() {
        // Confetti explosion first
        withAnimation(.easeOut(duration: 1.0)) {
            confettiOffset = 120
        }
        
        // Ring explosion effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            ringExplosion = true
        }
        
        // Level badge dramatic entrance
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 12).delay(0.4)) {
            levelBadgeScale = 1.0
            glowRadius = 20
        }
        
        // Badge rotation and glow
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            levelBadgeRotation = 360
        }
        
        // Content fade in
        withAnimation(.easeInOut(duration: 0.6).delay(0.7)) {
            animationOpacity = 1.0
        }
        
        // Button and special effects
        withAnimation(.interpolatingSpring(stiffness: 150, damping: 15).delay(1.0)) {
            animationScale = 1.0
        }
        
        // Auto-dismiss after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if isVisible {
                dismissCelebration()
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.4)) {
            animationOpacity = 0
            animationScale = 0.8
            levelBadgeScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
    
    // MARK: - Helper Functions
    private func getConfettiEmojis(for level: ProteinLevel) -> [String] {
        switch level {
        case .rookie: return ["🎉", "⚡", "🔥", "💪"]
        case .starter: return ["🚀", "⭐", "✨", "🎯"]
        case .consistent: return ["💎", "🏆", "👑", "⚡"]
        case .dedicated: return ["💙", "🌟", "❄️", "💫"]
        case .committed: return ["🥇", "👑", "🔥", "⚡"]
        case .advanced: return ["💜", "🔮", "✨", "🌟"]
        case .expert: return ["💙", "🌊", "❄️", "💫"]
        case .master: return ["💖", "🌸", "✨", "💫"]
        case .legend: return ["🌈", "⚡", "✨", "🎊", "🎉", "💥"]
        case .immortal: return ["👑", "⚫", "🥇", "💀", "⚡", "🔥"]
        }
    }
}

// MARK: - Enhanced Level Badge for Celebration (using existing LevelBadge initializer)

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LevelUpCelebrationView(
            newLevel: .dedicated,
            isVisible: true,
            onDismiss: { print("Level up dismissed") }
        )
    }
}