import Foundation
import SwiftData

// MARK: - Recipe Cache Service
// Speichert API-Rezepte permanent in SwiftData für offline Nutzung
@MainActor
class RecipeCacheService {
    static let shared = RecipeCacheService()
    private init() {}
    
    // MARK: - Seed Database from API
    func seedDatabaseFromAPI() async {
        print("🌱 Starting database seeding from Spoonacular API...")
        
        do {
            // Load different categories of high-protein recipes
            let categories = [
                ("high-protein", 20),      // General high-protein
                ("breakfast", 15),         // High-protein breakfast  
                ("lunch", 15),            // High-protein lunch
                ("snack", 10),            // High-protein snacks
                ("vegetarian", 10),       // Vegetarian high-protein
                ("vegan", 10)             // Vegan high-protein
            ]
            
            var totalRecipesSaved = 0
            
            for (diet, count) in categories {
                let recipes = try await RecipeAPIService.shared.searchByDiet(
                    DietType(rawValue: diet) ?? .highProtein, 
                    limit: count
                )
                
                for recipe in recipes {
                    await saveRecipeToDatabase(recipe)
                    totalRecipesSaved += 1
                    
                    // Small delay to respect API rate limits
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
                
                print("✅ Saved \(recipes.count) \(diet) recipes")
            }
            
            print("🎉 Database seeding complete! \(totalRecipesSaved) recipes saved.")
            
        } catch {
            print("❌ Error seeding database: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Save Recipe to Database
    private func saveRecipeToDatabase(_ apiRecipe: APIRecipe) async {
        // Get detailed recipe information
        do {
            let detailRecipe = try await RecipeAPIService.shared.getRecipeDetails(id: apiRecipe.id)
            
            // Convert to RecommendationCard with full details
            let card = createRecommendationCard(from: detailRecipe)
            
            // Save using DataManager
            await saveToSwiftData(card)
            
        } catch {
            print("⚠️ Could not get details for recipe \(apiRecipe.id): \(error)")
            // Save basic version without details
            let basicCard = apiRecipe.toRecommendationCard()
            await saveToSwiftData(basicCard)
        }
    }
    
    // MARK: - Create Full RecommendationCard
    private func createRecommendationCard(from detail: APIRecipeDetail) -> RecommendationCard {
        // Extract ingredients
        let ingredients = detail.extendedIngredients.map { ingredient in
            "\(ingredient.amount) \(ingredient.unit) \(ingredient.name)"
        }
        
        // Clean up instructions (remove HTML tags)
        let cleanInstructions = detail.instructions
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create tags based on nutrition and diet info
        var tags: [String] = []
        
        // Add protein tag
        if let protein = detail.nutrition.protein {
            tags.append("💪 \(Int(protein))g")
        }
        
        // Add time-based tags
        if detail.readyInMinutes <= 15 {
            tags.append("⚡ Schnell")
        } else if detail.readyInMinutes <= 30 {
            tags.append("🕒 Normal")
        }
        
        // Add calorie info
        if let calories = detail.nutrition.calories {
            if calories < 300 {
                tags.append("🪶 Leicht")
            } else if calories > 500 {
                tags.append("🔥 Sättigend")
            }
        }
        
        let card = RecommendationCard(
            recipeId: "api_\(detail.id)",
            title: detail.title,
            durationMin: detail.readyInMinutes,
            tags: tags,
            ingredients: ingredients,
            instructions: cleanInstructions.isEmpty ? "Zubereitung nach Zutaten" : cleanInstructions
        )
        
        card.proteinGrams = detail.nutrition.protein
        card.kcal = Int(detail.nutrition.calories ?? 300)
        card.category = determineCategory(from: detail)
        card.difficulty = detail.readyInMinutes <= 15 ? .easy : .medium
        
        return card
    }
    
    // MARK: - Determine Category
    private func determineCategory(from recipe: APIRecipeDetail) -> RecipeCategory {
        let title = recipe.title.lowercased()
        
        if title.contains("breakfast") || title.contains("morning") {
            return .breakfast
        } else if title.contains("lunch") || title.contains("sandwich") || title.contains("salad") {
            return .lunch  
        } else if title.contains("dinner") || title.contains("main") {
            return .dinner
        } else if title.contains("snack") || title.contains("bar") {
            return .snack
        } else if title.contains("dessert") || title.contains("sweet") {
            return .dessert
        } else if recipe.readyInMinutes <= 5 {
            return .protein_shot
        } else {
            return .lunch
        }
    }
    
    // MARK: - Save to SwiftData
    private func saveToSwiftData(_ card: RecommendationCard) async {
        DataManager.shared.saveCachedRecipe(card, source: "spoonacular")
        print("💾 Saved recipe: \(card.title)")
    }
    
    // MARK: - Load Cached Recipes
    func loadCachedRecipes() async -> [RecommendationCard] {
        return DataManager.shared.loadCachedRecipes()
    }
    
    // MARK: - Database Status
    func getCacheStatus() async -> RecipeCacheStatus {
        let stats = DataManager.shared.getCacheStatistics()
        
        return RecipeCacheStatus(
            recipesCount: stats.total,
            lastUpdate: Date(),
            needsSeeding: stats.total < 50
        )
    }
}

// MARK: - Cache Status Model
struct RecipeCacheStatus {
    let recipesCount: Int
    let lastUpdate: Date
    let needsSeeding: Bool
    
    var statusMessage: String {
        if needsSeeding {
            return "Datenbank leer - Seeding empfohlen"
        } else {
            return "\(recipesCount) Rezepte in Datenbank"
        }
    }
}

// MARK: - Usage in DataManager (methods already defined in DataManager)