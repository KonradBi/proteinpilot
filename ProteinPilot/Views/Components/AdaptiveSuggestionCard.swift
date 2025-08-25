import SwiftUI

struct AdaptiveSuggestionCard: View {
    let suggestion: AdaptiveMealSuggestion
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(suggestion.urgencyEmoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.context)
                        .font(.caption2)
                        .foregroundColor(urgencyColor)
                        .fontWeight(.medium)
                    
                    Text(suggestion.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Stats
            HStack(spacing: 16) {
                StatItem(
                    icon: "flame.fill",
                    value: "\(Int(suggestion.proteinAmount))g",
                    color: .blue
                )
                
                StatItem(
                    icon: "clock.fill",
                    value: "\(suggestion.prepTimeMinutes)min",
                    color: timeColor
                )
            }
            
            // Reason
            Text(suggestion.reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Add Button
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Hinzufügen")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(urgencyColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(
                    color: urgencyColor.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var urgencyColor: Color {
        switch suggestion.urgency {
        case .critical:
            return .red
        case .urgent:
            return .orange
        case .normal:
            return .blue
        }
    }
    
    private var timeColor: Color {
        switch suggestion.prepTimeMinutes {
        case ..<5:
            return .red
        case 5..<15:
            return .orange
        default:
            return .green
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}