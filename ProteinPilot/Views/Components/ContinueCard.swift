import SwiftUI

struct ContinueCard: View {
    let item: ScheduledItem?
    let onContinue: (ScheduledItem) -> Void
    
    var body: some View {
        if let item = item, item.status == .planned {
            Button(action: { onContinue(item) }) {
                HStack(spacing: 16) {
                    // Left: Icon and Progress
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.2),
                                        Color.orange.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: itemIcon(for: item))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    
                    // Middle: Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Weiter machen")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundColor(.orange.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                            
                            Spacer()
                        }
                        
                        Text(item.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(progressDescription(for: item))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Right: Action
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("Fortsetzen")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.orange.opacity(0.3),
                                            Color.orange.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .orange.opacity(0.1), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }
    
    private func itemIcon(for item: ScheduledItem) -> String {
        switch item.type {
        case .meal: return "fork.knife"
        case .intake: return "drop.fill"
        case .workout: return "figure.strengthtraining.functional"
        }
    }
    
    private func progressDescription(for item: ScheduledItem) -> String {
        switch item.type {
        case .meal: return "Zubereitung läuft..."
        case .intake: return "Portionierung offen"
        case .workout: return "Training pausiert"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 20) {
            // Example with in-progress meal
            ContinueCard(
                item: {
                    let item = ScheduledItem(type: .meal, title: "Kichererbsen-Curry", time: "12:30", day: Date())
                    item.status = .done
                    return item
                }(),
                onContinue: { item in
                    print("Continue: \(item.title)")
                }
            )
            
            // Example with no item (should not show)
            ContinueCard(
                item: nil,
                onContinue: { _ in }
            )
        }
    }
}