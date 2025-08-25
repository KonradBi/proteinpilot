import SwiftUI

struct QuickFoodChip: View {
    let food: FoodItem
    let onAdd: (Double) -> Void
    
    @State private var sessionCount: Int = 0
    @State private var lastTapTime = Date()
    
    // Session reset after 2 hours of inactivity
    private let sessionTimeoutInterval: TimeInterval = 7200
    
    var body: some View {
        Button(action: {
            incrementCount()
        }) {
            HStack(spacing: 8) {
                // Food emoji and name
                HStack(spacing: 8) {
                    if let emoji = food.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(.title2, weight: .medium))
                    } else {
                        // Fallback icon if no emoji
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(.body, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(food.name)
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                }
                
                // Counter badge - only show if count > 1
                if sessionCount > 1 {
                    Text("(\(sessionCount))")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Protein amount badge
                Text("\(Int(food.proteinPerPortion))g")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
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
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(sessionCount > 0 ? 0.16 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
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
            // Subtle glow when active
            .shadow(
                color: sessionCount > 0 ? Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(sessionCount > 0 ? 1.02 : 1.0)
        .animation(.interpolatingSpring(stiffness: 400, damping: 20), value: sessionCount)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    decrementCount()
                }
        )
        .onAppear {
            resetIfNeeded()
        }
    }
    
    private func incrementCount() {
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 25)) {
            sessionCount += 1
        }
        
        lastTapTime = Date()
        
        // Add protein for this portion
        onAdd(food.proteinPerPortion)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func decrementCount() {
        guard sessionCount > 0 else { return }
        
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 25)) {
            sessionCount -= 1
        }
        
        lastTapTime = Date()
        
        // Remove protein for this portion
        onAdd(-food.proteinPerPortion)
        
        // Stronger haptic for decrement
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func resetIfNeeded() {
        let timeSinceLastTap = Date().timeIntervalSince(lastTapTime)
        if timeSinceLastTap > sessionTimeoutInterval {
            sessionCount = 0
        }
    }
}

// MARK: - Session Management Extension
extension QuickFoodChip {
    /// Reset all counters (call when app enters background or on daily reset)
    static func resetAllSessions() {
        // This would be managed by the parent view or DataManager
        NotificationCenter.default.post(name: .resetQuickFoodSessions, object: nil)
    }
}

extension Notification.Name {
    static let resetQuickFoodSessions = Notification.Name("resetQuickFoodSessions")
}

// MARK: - Preview
#Preview {
    VStack(spacing: 12) {
        QuickFoodChip(
            food: FoodItem.defaultQuickFoods[0], // Ei
            onAdd: { protein in
                print("Added \(protein)g protein")
            }
        )
        
        QuickFoodChip(
            food: FoodItem.defaultQuickFoods[1], // Quark
            onAdd: { protein in
                print("Added \(protein)g protein")
            }
        )
        
        QuickFoodChip(
            food: FoodItem.defaultQuickFoods[4], // Proteinshake
            onAdd: { protein in
                print("Added \(protein)g protein")
            }
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.05, blue: 0.05),
                Color(red: 0.15, green: 0.08, blue: 0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}