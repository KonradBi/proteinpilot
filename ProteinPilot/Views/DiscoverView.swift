import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var mealSuggestions: [AdaptiveMealSuggestion] = []
    @State private var isLoading = true
    @State private var savedMeals: [AdaptiveMealSuggestion] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.09),
                        Color(red: 0.12, green: 0.10, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        headerSection
                        
                        if isLoading {
                            loadingSection
                        } else {
                            heroMealSection
                            categoriesSection
                            recommendationsSection
                        }
                        
                        if !savedMeals.isEmpty {
                            savedMealsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadMealSuggestions()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover")
                        .font(.system(size: 32, weight: .black, design: .rounded))
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
                    
                    Text("Personalisierte Protein-Empfehlungen")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    loadMealSuggestions()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.0))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 20)
    }
    
    private var loadingSection: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 20)
                                .padding(.horizontal, 40)
                        }
                    )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isLoading = false
                }
            }
        }
    }
    
    private var heroMealSection: some View {
        Group {
            if let heroMeal = mealSuggestions.first {
                VStack(alignment: .leading, spacing: 16) {
                    Text("🌟 Perfekt für jetzt")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                    
                    heroMealCard(heroMeal)
                }
            }
        }
    }
    
    private func heroMealCard(_ meal: AdaptiveMealSuggestion) -> some View {
        Button(action: { addMeal(meal) }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with urgency and protein
                HStack {
                    HStack(spacing: 6) {
                        Text(meal.urgencyEmoji)
                            .font(.title2)
                        Text(meal.urgency.displayName)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(urgencyColor(meal.urgency).opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(urgencyColor(meal.urgency).opacity(0.5), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(urgencyColor(meal.urgency))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                            Text("\(Int(meal.proteinAmount))g")
                                .font(.system(.title3, design: .rounded, weight: .black))
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.0))
                        
                        Text("Protein")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 12) {
                    Text(meal.name)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(meal.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(meal.prepTimeMinutes) Min")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("KI-Empfehlung")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                }
                
                Spacer()
            }
            .frame(height: 220)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kategorien")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                categoryCard("⚡️", "Schnell", "Unter 5 Min", Color.green)
                categoryCard("🚶‍♂️", "Unterwegs", "Für Mobility", Color.blue)
                categoryCard("🏠", "Zuhause", "Zeit zum Kochen", Color.orange)
                categoryCard("💪", "High Protein", "40g+", Color.purple)
            }
        }
    }
    
    private func categoryCard(_ emoji: String, _ title: String, _ subtitle: String, _ color: Color) -> some View {
        Button(action: {
            // Filter suggestions by category
        }) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title)
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weitere Empfehlungen")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(mealSuggestions.dropFirst(1).prefix(6)), id: \.id) { meal in
                    compactMealCard(meal)
                }
            }
        }
    }
    
    private func compactMealCard(_ meal: AdaptiveMealSuggestion) -> some View {
        Button(action: { addMeal(meal) }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(meal.urgencyEmoji)
                        .font(.title3)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(Int(meal.proteinAmount))g")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.0))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(meal.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(meal.prepTimeMinutes) Min")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .frame(height: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gespeicherte Mahlzeiten")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(savedMeals, id: \.id) { meal in
                        compactMealCard(meal)
                            .frame(width: 160)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }
    
    private func urgencyColor(_ urgency: MealUrgency) -> Color {
        switch urgency {
        case .critical: return .red
        case .urgent: return .orange
        case .normal: return .blue
        }
    }
    
    private func addMeal(_ meal: AdaptiveMealSuggestion) {
        dataManager.addProteinEntry(
            quantity: 100,
            proteinGrams: meal.proteinAmount,
            mealType: "Snack"
        )
        
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func loadMealSuggestions() {
        isLoading = true
        
        Task {
            do {
                let suggestions = try await dataManager.generateAdaptiveMealSuggestions()
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.mealSuggestions = suggestions
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    // Fallback suggestions
                    self.mealSuggestions = [
                        AdaptiveMealSuggestion(
                            name: "Protein-Smoothie",
                            proteinAmount: 25,
                            prepTimeMinutes: 2,
                            reason: "Schneller Whey-Shake mit Banane",
                            context: "⚡ Schnell",
                            priority: 90,
                            urgency: .normal,
                            situation: .onTheGo
                        ),
                        AdaptiveMealSuggestion(
                            name: "Greek Yogurt Bowl",
                            proteinAmount: 18,
                            prepTimeMinutes: 3,
                            reason: "Griechischer Joghurt mit Nüssen",
                            context: "🍽️ Normal",
                            priority: 80,
                            urgency: .normal,
                            situation: .home
                        )
                    ]
                    self.isLoading = false
                }
            }
        }
    }
}

extension MealUrgency {
    var displayName: String {
        switch self {
        case .critical: return "Dringend"
        case .urgent: return "Wichtig"
        case .normal: return "Normal"
        }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(DataManager.shared)
}