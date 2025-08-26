import Foundation
import SwiftData

// MARK: - Pre-Launch Recipe Seeding Service
// Developer tool to collect 200+ recipes before app launch
@MainActor
class PreLaunchSeedingService {
    static let shared = PreLaunchSeedingService()
    private init() {}
    
    // MARK: - Manual Seeding (Developer Use Only)
    
    /// Run this function during development to collect 200+ recipes
    /// Use your 150 free API calls per day over ~2 weeks to build recipe database
    func runPreLaunchSeeding() async {
        guard APIConfig.enableAPIIntegration && APIConfig.isAPIKeyValid else {
            print("❌ API not configured. Set enableAPIIntegration = true and add your API key")
            return
        }
        
        print("🚀 Starting pre-launch recipe seeding...")
        print("📊 Target: \(APIConfig.targetRecipeCount) recipes")
        print("⏰ Using max \(APIConfig.maxDailyRequests) requests today")
        
        let stats = DataManager.shared.getCacheStatistics()
        print("📦 Current cache: \(stats.total) recipes (\(stats.localRecipes) local, \(stats.apiRecipes) API)")
        
        if stats.total >= APIConfig.targetRecipeCount {
            print("✅ Already have \(stats.total) recipes - seeding not needed!")
            return
        }
        
        let remaining = APIConfig.targetRecipeCount - stats.total
        print("🎯 Need \(remaining) more recipes")
        
        await seedByCategories(maxRequests: APIConfig.maxDailyRequests)
        
        let finalStats = DataManager.shared.getCacheStatistics()
        print("🎉 Seeding session complete!")
        print("📊 Final count: \(finalStats.total) recipes (\(finalStats.apiRecipes) from API)")
        
        if finalStats.total >= APIConfig.targetRecipeCount {
            print("✅ TARGET REACHED! Ready for launch - you can now disable API")
            print("💡 Set enableAPIIntegration = false for production")
        } else {
            let stillNeeded = APIConfig.targetRecipeCount - finalStats.total
            print("📝 Still need \(stillNeeded) recipes - run again tomorrow")
        }
    }
    
    // MARK: - Category-Based Seeding
    private func seedByCategories(maxRequests: Int) async {
        var requestsUsed = 0
        
        for (category, targetCount) in APIConfig.seedingCategories {
            guard requestsUsed < maxRequests else {
                print("⚠️ Daily request limit reached (\(requestsUsed)/\(maxRequests))")
                break
            }
            
            print("🔍 Seeding \(category) recipes (target: \(targetCount))...")
            
            do {
                // Check how many we already have for this category
                let existingCount = countRecipesForCategory(category)
                let needed = max(0, targetCount - existingCount)
                
                if needed == 0 {
                    print("✅ Already have enough \(category) recipes (\(existingCount))")
                    continue
                }
                
                let actualLimit = min(needed, maxRequests - requestsUsed, 25) // API max per call
                
                let recipes = try await RecipeAPIService.shared.searchByDiet(
                    DietType(rawValue: category) ?? .highProtein, 
                    limit: actualLimit
                )
                
                // Save each recipe with category tag
                for recipe in recipes {
                    let card = recipe.toRecommendationCard()
                    card.tags.append("📂 \(category)")
                    
                    DataManager.shared.saveCachedRecipe(card, source: "spoonacular_\(category)")
                    requestsUsed += 1
                    
                    // Rate limiting - small delay between requests
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                }
                
                print("✅ Added \(recipes.count) \(category) recipes (total requests: \(requestsUsed))")
                
            } catch {
                print("❌ Error seeding \(category): \(error)")
                continue
            }
            
            // Longer pause between categories
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        print("📊 Session summary: Used \(requestsUsed) requests")
    }
    
    // MARK: - Recipe Counting
    private func countRecipesForCategory(_ category: String) -> Int {
        // Count existing recipes with this category tag
        let allRecipes = DataManager.shared.loadCachedRecipes(from: "spoonacular_\(category)")
        return allRecipes.count
    }
    
    // MARK: - Seeding Status
    func getSeedingStatus() -> SeedingStatus {
        let stats = DataManager.shared.getCacheStatistics()
        let progress = Float(stats.total) / Float(APIConfig.targetRecipeCount)
        
        return SeedingStatus(
            currentCount: stats.total,
            targetCount: APIConfig.targetRecipeCount,
            progress: min(progress, 1.0),
            isComplete: stats.total >= APIConfig.targetRecipeCount,
            apiRecipes: stats.apiRecipes,
            localRecipes: stats.localRecipes
        )
    }
    
    // MARK: - Export for Production
    /// Generate a production-ready recipe bundle (no API needed)
    func exportRecipeBundleForProduction() async -> String {
        let allRecipes = DataManager.shared.loadCachedRecipes()
        
        let summary = """
        📦 PRODUCTION RECIPE BUNDLE
        
        Total Recipes: \(allRecipes.count)
        High-Protein (20g+): \(allRecipes.filter { ($0.proteinGrams ?? 0) >= 20 }.count)
        Quick Recipes (<15min): \(allRecipes.filter { $0.durationMin <= 15 }.count)
        
        Categories:
        - Breakfast: \(allRecipes.filter { $0.category == .breakfast }.count)
        - Lunch: \(allRecipes.filter { $0.category == .lunch }.count)  
        - Dinner: \(allRecipes.filter { $0.category == .dinner }.count)
        - Snacks: \(allRecipes.filter { $0.category == .snack }.count)
        
        ✅ Ready for production launch!
        💡 Set enableAPIIntegration = false
        """
        
        print(summary)
        return summary
    }
}

// MARK: - Seeding Status Model
struct SeedingStatus {
    let currentCount: Int
    let targetCount: Int
    let progress: Float // 0.0 to 1.0
    let isComplete: Bool
    let apiRecipes: Int
    let localRecipes: Int
    
    var statusMessage: String {
        if isComplete {
            return "✅ Seeding complete! \(currentCount)/\(targetCount) recipes ready for launch"
        } else {
            let remaining = targetCount - currentCount
            return "🚧 In progress: \(currentCount)/\(targetCount) recipes (\(remaining) remaining)"
        }
    }
    
    var progressPercentage: String {
        return "\(Int(progress * 100))%"
    }
}

// MARK: - Developer Extension
extension DataManager {
    /// Developer helper: Run pre-launch seeding
    func runPreLaunchSeeding() async {
        await PreLaunchSeedingService.shared.runPreLaunchSeeding()
    }
    
    /// Check seeding progress
    func getSeedingProgress() -> SeedingStatus {
        return PreLaunchSeedingService.shared.getSeedingStatus()
    }
}