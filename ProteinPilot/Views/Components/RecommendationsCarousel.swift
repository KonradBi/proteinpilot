import SwiftUI

struct RecommendationsCarousel: View {
    let recommendations: [RecommendationCard]
    let selectedDate: Date
    let onAddToPlan: (RecommendationCard, Date) -> Void
    let onCardTapped: (RecommendationCard) -> Void
    
    @State private var selectedFilter: FilterTag = .all
    
    private var filteredRecommendations: [RecommendationCard] {
        switch selectedFilter {
        case .all:
            return recommendations
        case .quick:
            return recommendations.filter { $0.durationMin <= 20 }
        case .proteinRich:
            return recommendations.filter { ($0.proteinGrams ?? 0) >= 20 }
        case .lowCalorie:
            return recommendations.filter { ($0.kcal ?? 0) <= 400 }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Filters
            headerSection
            
            // Recommendations Scroll View
            if filteredRecommendations.isEmpty {
                emptyState
            } else {
                recommendationsScroll
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8),
                                    Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                    
                    Image(systemName: "star.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.9, blue: 0.0),
                                    Color(red: 1.0, green: 0.6, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(.subheadline, weight: .bold))
                }
                
                Text("Empfehlungen")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterTag.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var recommendationsScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(filteredRecommendations, id: \.recipeId) { recommendation in
                    RecommendationCardView(
                        recommendation: recommendation,
                        onAddToPlan: { 
                            onAddToPlan(recommendation, selectedDate)
                        },
                        onCardTapped: {
                            onCardTapped(recommendation)
                        }
                    )
                    .frame(width: 280)
                }
            }
            .padding(.horizontal, 2)
        }
        .contentMargins(.horizontal, 14)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Keine Empfehlungen gefunden")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct RecommendationCardView: View {
    let recommendation: RecommendationCard
    let onAddToPlan: () -> Void
    let onCardTapped: () -> Void
    
    var body: some View {
        Button(action: onCardTapped) {
            VStack(alignment: .leading, spacing: 0) {
                // Image placeholder (top section)
                imageSection
                
                // Content section
                contentSection
                
                // Action section
                actionSection
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
    
    private var imageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                            Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
            
            // Placeholder image/icon
            Image(systemName: "fork.knife")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(recommendation.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Stats row
            statsRow
            
            // Tags
            if !recommendation.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(recommendation.tags.prefix(3)), id: \.self) { tag in
                            Text(tag)
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var actionSection: some View {
        HStack(spacing: 12) {
            Button(action: onAddToPlan) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(.subheadline, weight: .semibold))
                    
                    Text("Zu Plan hinzufügen")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
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
                        .shadow(
                            color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.4),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var statsRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(recommendation.durationMin) min")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if let kcal = recommendation.kcal {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(.caption2, weight: .medium))
                        .foregroundColor(.orange.opacity(0.8))
                    
                    Text("\(kcal) kcal")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            if let protein = recommendation.proteinGrams {
                HStack(spacing: 4) {
                    Text("💪")
                        .font(.system(.caption2))
                    
                    Text("\(Int(protein))g")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                }
            }
            
            Spacer()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    isSelected ?
                                    Color.white.opacity(0.3) :
                                    Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

enum FilterTag: CaseIterable {
    case all, quick, proteinRich, lowCalorie
    
    var title: String {
        switch self {
        case .all: return "Alle"
        case .quick: return "Schnell"
        case .proteinRich: return "Proteinreich"
        case .lowCalorie: return "Kalorienarm"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        RecommendationsCarousel(
            recommendations: [
                RecommendationCard(recipeId: "1", title: "Griechischer Joghurt mit Beeren", durationMin: 5, tags: ["Schnell", "Proteinreich"]),
                RecommendationCard(recipeId: "2", title: "Protein Pancakes", durationMin: 15, tags: ["Lecker", "Sättigend"]),
                RecommendationCard(recipeId: "3", title: "Hühnerbrust mit Reis", durationMin: 25, tags: ["Klassisch"])
            ],
            selectedDate: Date(),
            onAddToPlan: { recommendation, date in
                print("Add to plan: \(recommendation.title)")
            },
            onCardTapped: { recommendation in
                print("Card tapped: \(recommendation.title)")
            }
        )
    }
}