import Foundation

struct APIConfig {
    // MARK: - Spoonacular API
    // Get your free API key at: https://spoonacular.com/food-api
    // Free tier: 150 requests/day
    static let spoonacularAPIKey = "REPLACE_WITH_YOUR_API_KEY"
    
    // MARK: - API Settings
    static let enableAPIIntegration = false // Set to true ONLY for pre-launch seeding
    static let enableUserAPIAccess = false  // Always false in production - users get pre-seeded recipes
    
    // MARK: - Validation
    static var isAPIKeyValid: Bool {
        return !spoonacularAPIKey.isEmpty && 
               spoonacularAPIKey != "REPLACE_WITH_YOUR_API_KEY" &&
               enableAPIIntegration
    }
    
    // MARK: - Pre-Launch Seeding Configuration
    static let targetRecipeCount = 200      // Goal: 200+ recipes before launch
    static let seedingBatchSize = 20        // Recipes per category
    static let maxDailyRequests = 140       // Leave buffer under 150 limit
    
    // Categories for comprehensive seeding
    static let seedingCategories = [
        ("high-protein", 25),    // Core high-protein recipes
        ("breakfast", 20),       // High-protein breakfast  
        ("lunch", 25),           // High-protein lunch
        ("dinner", 25),          // High-protein dinner
        ("snack", 20),           // High-protein snacks
        ("vegetarian", 20),      // Vegetarian high-protein
        ("vegan", 15),           // Vegan high-protein
        ("quick", 25),           // Under 15min recipes  
        ("protein-powder", 15),  // Protein shake recipes
        ("meal-prep", 10)        // Batch cooking recipes
    ]
    
    // MARK: - Instructions
    /*
     🚀 So aktivierst du die API-Integration:
     
     1. Gehe zu https://spoonacular.com/food-api
     2. Erstelle einen kostenlosen Account  
     3. Kopiere deinen API-Key
     4. Ersetze "REPLACE_WITH_YOUR_API_KEY" oben mit deinem Key
     5. Setze enableAPIIntegration = true
     
     ✅ Kostenlos: 150 Requests/Tag
     💰 Paid: $29/Monat für 1.500 Requests/Tag
     
     🔐 Sicherheit: 
     - Niemals API-Keys in Git committen
     - Für Production: Verwende Environment Variables
     - Für Development: Diese Datei in .gitignore
     */
}