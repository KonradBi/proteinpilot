import SwiftUI

struct RecipeDetailView: View {
    let recipe: RecommendationCard
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Info
                    headerSection
                    
                    // Tags/Properties
                    tagsSection
                    
                    // Ingredients
                    ingredientsSection
                    
                    // Instructions
                    instructionsSection
                    
                    // Nutrition Info
                    nutritionSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120) // Space for buttons
            }
            .background(homeBackground)
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .overlay(alignment: .bottom) {
            actionButtons
        }
    }
    
    // MARK: - Background (matching main screen)
    private var homeBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.05, blue: 0.05),  // Deep red
                Color(red: 0.15, green: 0.08, blue: 0.02), // Red-brown
                Color(red: 0.18, green: 0.12, blue: 0.03)  // Warm brown
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Duration and Difficulty
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                    Text("\(recipe.durationMin) Min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                    Text(recipe.difficulty.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Category Badge
            Text(recipe.category.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.2),
                                    Color(red: 1.0, green: 0.6, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
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
    }
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.8),
                                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                    
                    Image(systemName: "tag.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.2),
                                    Color(red: 1.0, green: 0.6, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(.subheadline, weight: .bold))
                }
                
                Text("Eigenschaften")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(recipe.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.4), lineWidth: 0.5)
                                )
                        )
                }
            }
        }
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.8),
                                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                    
                    Image(systemName: "list.bullet")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.2),
                                    Color(red: 1.0, green: 0.6, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(.subheadline, weight: .bold))
                }
                
                Text("Zutaten")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1).")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                            .frame(width: 24, alignment: .leading)
                        
                        Text(ingredient)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
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
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.8),
                                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                    
                    Image(systemName: "text.alignleft")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.2),
                                    Color(red: 1.0, green: 0.6, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(.subheadline, weight: .bold))
                }
                
                Text("Zubereitung")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
            }
            
            Text(recipe.instructions)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
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
        }
    }
    
    // MARK: - Nutrition Section
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.8),
                                    Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                    
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.2),
                                    Color(red: 1.0, green: 0.6, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(.subheadline, weight: .bold))
                }
                
                Text("Nährwerte")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 12) {
                // Protein
                VStack(spacing: 8) {
                    Text("💪")
                        .font(.title)
                    Text("\(Int(recipe.proteinGrams ?? 0))g")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundColor(.white)
                    Text("Protein")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.4),
                                            Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                
                // Calories
                VStack(spacing: 8) {
                    Text("🔥")
                        .font(.title)
                    Text("\(recipe.kcal ?? 0)")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundColor(.white)
                    Text("kcal")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                )
                
                // Time
                VStack(spacing: 8) {
                    Text("⏱️")
                        .font(.title)
                    Text("\(recipe.durationMin)")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundColor(.white)
                    Text("Min")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Add to Plan Button
            Button(action: {
                // TODO: Add to plan functionality
                print("Add to plan: \(recipe.title)")
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Zu Tagesplan hinzufügen")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.2),
                                    Color(red: 1.0, green: 0.6, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(.plain)
            
            // Consume Directly Button
            Button(action: {
                // TODO: Add directly as consumed
                print("Consume directly: \(recipe.title)")
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Direkt als gegessen markieren")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.2))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.6),
                                            Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    RecipeDetailView(recipe: RecommendationCard(
        recipeId: "test", 
        title: "Protein-Shot Milchreis", 
        durationMin: 2, 
        tags: ["⚡ Blitz", "🥛 Instant", "💪 35g"],
        ingredients: ["200ml Milch", "30g Proteinpulver", "2 EL Milchreis", "1 TL Zimt"],
        instructions: "Milch erwärmen, Proteinpulver einrühren, Milchreis hinzufügen."
    ))
}