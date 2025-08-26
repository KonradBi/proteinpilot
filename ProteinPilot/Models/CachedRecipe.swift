import Foundation
import SwiftData

// MARK: - Cached Recipe Model for SwiftData
@Model
final class CachedRecipe {
    var recipeId: String
    var title: String
    var durationMin: Int
    var proteinGrams: Double
    var kcal: Int
    var tags: [String]
    var ingredients: [String]
    var instructions: String
    var difficulty: String
    var category: String
    var createdAt: Date
    var apiSource: String // "spoonacular", "local", etc.
    
    init(
        recipeId: String,
        title: String,
        durationMin: Int,
        proteinGrams: Double,
        kcal: Int,
        tags: [String] = [],
        ingredients: [String] = [],
        instructions: String = "",
        difficulty: String = "easy",
        category: String = "lunch",
        apiSource: String = "spoonacular"
    ) {
        self.recipeId = recipeId
        self.title = title
        self.durationMin = durationMin
        self.proteinGrams = proteinGrams
        self.kcal = kcal
        self.tags = tags
        self.ingredients = ingredients
        self.instructions = instructions
        self.difficulty = difficulty
        self.category = category
        self.createdAt = Date()
        self.apiSource = apiSource
    }
}

// MARK: - Extensions
extension CachedRecipe {
    // Convert to RecommendationCard for UI
    func toRecommendationCard() -> RecommendationCard {
        let card = RecommendationCard(
            recipeId: recipeId,
            title: title,
            durationMin: durationMin,
            tags: tags,
            ingredients: ingredients,
            instructions: instructions
        )
        
        card.proteinGrams = proteinGrams
        card.kcal = kcal
        card.difficulty = RecipeDifficulty(rawValue: difficulty) ?? .easy
        card.category = RecipeCategory(rawValue: category) ?? .lunch
        
        return card
    }
    
    // Create from RecommendationCard
    static func from(_ card: RecommendationCard, source: String = "local") -> CachedRecipe {
        return CachedRecipe(
            recipeId: card.recipeId,
            title: card.title,
            durationMin: card.durationMin,
            proteinGrams: card.proteinGrams ?? 25.0,
            kcal: card.kcal ?? 300,
            tags: card.tags,
            ingredients: card.ingredients,
            instructions: card.instructions,
            difficulty: card.difficulty.rawValue,
            category: card.category.rawValue,
            apiSource: source
        )
    }
}

// MARK: - DataManager Extension for Cached Recipes
extension DataManager {
    
    // MARK: - Save Recipe to Cache
    func saveCachedRecipe(_ recipe: RecommendationCard, source: String = "api") {
        let cachedRecipe = CachedRecipe.from(recipe, source: source)
        context.insert(cachedRecipe)
        
        do {
            try context.save()
            print("💾 Saved recipe to cache: \(recipe.title)")
        } catch {
            print("❌ Error saving cached recipe: \(error)")
        }
    }
    
    // MARK: - Load All Cached Recipes  
    func loadCachedRecipes() -> [RecommendationCard] {
        let request = FetchDescriptor<CachedRecipe>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let cachedRecipes = try context.fetch(request)
            return cachedRecipes.map { $0.toRecommendationCard() }
        } catch {
            print("❌ Error loading cached recipes: \(error)")
            return []
        }
    }
    
    // MARK: - Load Recipes by Source
    func loadCachedRecipes(from source: String) -> [RecommendationCard] {
        let request = FetchDescriptor<CachedRecipe>(
            predicate: #Predicate { recipe in recipe.apiSource == source },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let cachedRecipes = try context.fetch(request)
            return cachedRecipes.map { $0.toRecommendationCard() }
        } catch {
            print("❌ Error loading cached recipes from \(source): \(error)")
            return []
        }
    }
    
    // MARK: - Check if Recipe Exists
    func recipeExists(_ recipeId: String) -> Bool {
        let request = FetchDescriptor<CachedRecipe>(
            predicate: #Predicate { recipe in recipe.recipeId == recipeId }
        )
        
        do {
            let results = try context.fetch(request)
            return !results.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - Get Cache Statistics
    func getCacheStatistics() -> (apiRecipes: Int, localRecipes: Int, total: Int) {
        do {
            let apiRequest = FetchDescriptor<CachedRecipe>(
                predicate: #Predicate { recipe in recipe.apiSource == "spoonacular" }
            )
            let localRequest = FetchDescriptor<CachedRecipe>(
                predicate: #Predicate { recipe in recipe.apiSource == "local" }
            )
            let totalRequest = FetchDescriptor<CachedRecipe>()
            
            let apiCount = try context.fetch(apiRequest).count
            let localCount = try context.fetch(localRequest).count  
            let totalCount = try context.fetch(totalRequest).count
            
            return (apiRecipes: apiCount, localRecipes: localCount, total: totalCount)
            
        } catch {
            print("❌ Error getting cache statistics: \(error)")
            return (apiRecipes: 0, localRecipes: 0, total: 0)
        }
    }
    
    // MARK: - Seed Local Recipes to Cache
    func seedLocalRecipesToCache() {
        print("🌱 Seeding local recipes to cache...")
        
        // Your 17 handcrafted recipes would be saved here
        let localRecipes = createLocalRecommendations() // Your existing recipes
        
        for recipe in localRecipes {
            if !recipeExists(recipe.recipeId) {
                saveCachedRecipe(recipe, source: "local")
            }
        }
        
        let stats = getCacheStatistics()
        print("✅ Local seeding complete. Cache: \(stats.localRecipes) local, \(stats.apiRecipes) API, \(stats.total) total")
    }
    
    private func createLocalRecommendations() -> [RecommendationCard] {
        // Get the existing handcrafted recipes from DataManager
        // This references the recipes defined in your NewHomeView or similar
        let localRecipes: [RecommendationCard] = []
        
        // TODO: Extract recipes from existing code - for now return empty
        // In future iteration, move the 17 handcrafted recipes here
        return localRecipes
    }
}