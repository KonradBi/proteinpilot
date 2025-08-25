import SwiftUI

// Minimal Demo für Tap-to-Increment QuickFood Chips
// Zeigt die perfekte UX für schnelles Protein-Tracking

struct TapIncrementDemo: View {
    @State private var totalProtein: Double = 0
    @State private var sessionCounts: [String: Int] = [:]
    
    // Demo Food Items
    let demoFoods = [
        DemoFood(id: "ei", name: "Ei", emoji: "🥚", proteinPerPortion: 6.5, defaultPortion: "1 Stück"),
        DemoFood(id: "quark", name: "Quark", emoji: "🧀", proteinPerPortion: 12.0, defaultPortion: "100g"),
        DemoFood(id: "haehnchen", name: "Hähnchen", emoji: "🐔", proteinPerPortion: 23.0, defaultPortion: "100g"),
        DemoFood(id: "thunfisch", name: "Thunfisch", emoji: "🐟", proteinPerPortion: 20.0, defaultPortion: "1 Dose"),
        DemoFood(id: "shake", name: "Shake", emoji: "🥛", proteinPerPortion: 25.0, defaultPortion: "1 Scoop"),
        DemoFood(id: "linsen", name: "Linsen", emoji: "🫘", proteinPerPortion: 9.0, defaultPortion: "100g")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            headerView
            
            // Protein Ring
            proteinRingView
            
            // Instructions
            instructionsView
            
            // Quick Food Chips
            quickFoodGrid
            
            // Reset Button
            resetButton
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.05, blue: 0.05),
                    Color(red: 0.15, green: 0.08, blue: 0.02),
                    Color(red: 0.18, green: 0.12, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .ignoresSafeArea()
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("🚀 Tap-to-Increment Demo")
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundColor(.white)
            
            Text("Mehrfach tippen für Anzahl • Long-Press für Rückgängig")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var proteinRingView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 8)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: min(totalProtein / 100, 1.0))
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 1.0, green: 0.65, blue: 0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: totalProtein)
            
            VStack(spacing: 4) {
                Text("\(Int(totalProtein))")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Protein")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                instractionItem(icon: "hand.tap.fill", text: "Einmal tippen\n= 1 Portion", color: .green)
                instractionItem(icon: "hand.tap.fill", text: "Mehrmals tippen\n= Mehrere Portionen", color: .blue)
                instractionItem(icon: "hand.point.up.left.fill", text: "Long Press\n= Rückgängig", color: .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func instractionItem(icon: String, text: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickFoodGrid: some View {
        VStack(spacing: 12) {
            Text("Quick Food Chips")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 12) {
                ForEach(demoFoods, id: \.id) { food in
                    DemoFoodChip(
                        food: food,
                        sessionCount: sessionCounts[food.id] ?? 0,
                        onTap: { handleTap(food) },
                        onLongPress: { handleLongPress(food) }
                    )
                }
            }
        }
    }
    
    private var resetButton: some View {
        Button(action: resetSession) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                Text("Session Reset")
            }
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.9))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func handleTap(_ food: DemoFood) {
        withAnimation(.interpolatingSpring(stiffness: 600, dampingFraction: 0.8)) {
            sessionCounts[food.id, default: 0] += 1
            totalProtein += food.proteinPerPortion
        }
        
        // Haptic Feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func handleLongPress(_ food: DemoFood) {
        guard sessionCounts[food.id, default: 0] > 0 else { return }
        
        withAnimation(.interpolatingSpring(stiffness: 600, dampingFraction: 0.8)) {
            sessionCounts[food.id, default: 0] -= 1
            totalProtein = max(0, totalProtein - food.proteinPerPortion)
        }
        
        // Haptic Feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func resetSession() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            sessionCounts.removeAll()
            totalProtein = 0
        }
        
        // Haptic Feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
}

struct DemoFood {
    let id: String
    let name: String
    let emoji: String
    let proteinPerPortion: Double
    let defaultPortion: String
}

struct DemoFoodChip: View {
    let food: DemoFood
    let sessionCount: Int
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Emoji und Name
                HStack(spacing: 6) {
                    Text(food.emoji)
                        .font(.system(.body, weight: .medium))
                    
                    Text(food.name)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Counter Badge (nur wenn > 1)
                if sessionCount > 1 {
                    Text("×\(sessionCount)")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                        )
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Protein Badge
                Text("\(Int(food.proteinPerPortion))g")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0),
                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(sessionCount > 0 ? 0.16 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: sessionCount > 0 ? 
                                        [Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3)] :
                                        [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: sessionCount > 0 ? Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.3) : .clear,
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(sessionCount > 0 ? 1.02 : 1.0)
        .animation(.interpolatingSpring(stiffness: 400, dampingFraction: 20), value: sessionCount)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

#Preview {
    TapIncrementDemo()
}