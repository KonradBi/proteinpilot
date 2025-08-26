import Foundation

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidConfiguration
    case httpError(Int)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "API nicht konfiguriert. Bitte API-Key in APIConfig.swift eintragen."
        case .httpError(let code):
            return "HTTP Error \(code). Überprüfe API-Key und Quota."
        case .decodingError:
            return "Fehler beim Verarbeiten der API-Antwort."
        case .networkError:
            return "Netzwerkfehler. Überprüfe deine Internetverbindung."
        }
    }
}

// MARK: - Recipe API Service (Spoonacular Integration)
class RecipeAPIService {
    static let shared = RecipeAPIService()
    private let baseURL = "https://api.spoonacular.com/recipes"
    private let apiKey = APIConfig.spoonacularAPIKey
    
    private init() {}
    
    // MARK: - Search High-Protein Recipes
    func searchHighProteinRecipes() async throws -> [APIRecipe] {
        // Check if API is enabled and key is valid
        guard APIConfig.isAPIKeyValid else {
            throw APIError.invalidConfiguration
        }
        
        let params = [
            "apiKey": apiKey,
            "diet": "high-protein",
            "number": "50", // Get 50 recipes
            "addRecipeInformation": "true",
            "addRecipeNutrition": "true",
            "minProtein": "20", // Minimum 20g protein
            "sort": "protein", // Sort by protein content
            "cuisine": "international"
        ]
        
        let url = buildURL(endpoint: "/complexSearch", params: params)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let searchResponse = try JSONDecoder().decode(RecipeSearchResponse.self, from: data)
        return searchResponse.results
    }
    
    // MARK: - Get Recipe Details
    func getRecipeDetails(id: Int) async throws -> APIRecipeDetail {
        let params = [
            "apiKey": apiKey,
            "includeNutrition": "true"
        ]
        
        let url = buildURL(endpoint: "/\(id)/information", params: params)
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return try JSONDecoder().decode(APIRecipeDetail.self, from: data)
    }
    
    // MARK: - Search by Dietary Preferences
    func searchByDiet(_ diet: DietType, limit: Int = 20) async throws -> [APIRecipe] {
        let params = [
            "apiKey": apiKey,
            "diet": diet.rawValue,
            "number": "\(limit)",
            "addRecipeInformation": "true",
            "addRecipeNutrition": "true",
            "minProtein": "15"
        ]
        
        let url = buildURL(endpoint: "/complexSearch", params: params)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(RecipeSearchResponse.self, from: data)
        
        return response.results
    }
    
    // MARK: - Helper Methods
    private func buildURL(endpoint: String, params: [String: String]) -> URL {
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
}

// MARK: - API Response Models
struct RecipeSearchResponse: Codable {
    let results: [APIRecipe]
    let offset: Int
    let number: Int
    let totalResults: Int
}

struct APIRecipe: Codable, Identifiable {
    let id: Int
    let title: String
    let image: String?
    let readyInMinutes: Int
    let servings: Int
    let nutrition: NutritionInfo?
    let summary: String?
    let cuisines: [String]?
    let diets: [String]?
    let dishTypes: [String]?
}

struct APIRecipeDetail: Codable {
    let id: Int
    let title: String
    let image: String?
    let readyInMinutes: Int
    let servings: Int
    let instructions: String
    let extendedIngredients: [Ingredient]
    let nutrition: NutritionInfo
    let summary: String
}

struct Ingredient: Codable {
    let id: Int
    let name: String
    let amount: Double
    let unit: String
    let original: String
}

struct NutritionInfo: Codable {
    let nutrients: [Nutrient]
    
    var protein: Double? {
        nutrients.first { $0.name.lowercased().contains("protein") }?.amount
    }
    
    var calories: Double? {
        nutrients.first { $0.name.lowercased().contains("calories") }?.amount
    }
}

struct Nutrient: Codable {
    let name: String
    let amount: Double
    let unit: String
}

enum DietType: String, CaseIterable {
    case highProtein = "high-protein"
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case ketogenic = "ketogenic"
    case paleo = "paleo"
}

// MARK: - Extension to Convert API Recipe to RecommendationCard
extension APIRecipe {
    func toRecommendationCard() -> RecommendationCard {
        let proteinAmount = nutrition?.protein ?? 25.0
        let calorieAmount = Int(nutrition?.calories ?? 300.0)
        
        // Create tags based on API data
        var tags: [String] = []
        
        // Add protein tag
        tags.append("💪 \(Int(proteinAmount))g")
        
        // Add diet tags
        if let diets = diets {
            for diet in diets.prefix(2) { // Limit to 2 diet tags
                switch diet.lowercased() {
                case "vegetarian": tags.append("🌱 Vegetarisch")
                case "vegan": tags.append("🌱 Vegan")
                case "ketogenic": tags.append("🥑 Keto")
                case "paleo": tags.append("🥩 Paleo")
                default: break
                }
            }
        }
        
        // Add time-based tags
        if readyInMinutes <= 15 {
            tags.append("⚡ Schnell")
        } else if readyInMinutes <= 30 {
            tags.append("🕒 Mittel")
        }
        
        // Create ingredients list (simplified for now)
        let ingredientsList = ["Siehe API-Details"] // Would be populated from detailed API call
        
        let card = RecommendationCard(
            recipeId: "api_\(id)",
            title: title,
            durationMin: readyInMinutes,
            tags: tags,
            ingredients: ingredientsList,
            instructions: summary ?? "Detaillierte Anleitung über API abrufen"
        )
        
        card.proteinGrams = proteinAmount
        card.kcal = calorieAmount
        card.category = determineCategory()
        card.difficulty = readyInMinutes <= 15 ? .easy : .medium
        
        return card
    }
    
    private func determineCategory() -> RecipeCategory {
        guard let dishTypes = dishTypes?.first?.lowercased() else {
            return .protein_shot
        }
        
        switch dishTypes {
        case let type where type.contains("breakfast"):
            return .breakfast
        case let type where type.contains("lunch"):
            return .lunch
        case let type where type.contains("dinner"):
            return .dinner
        case let type where type.contains("snack"):
            return .snack
        case let type where type.contains("dessert"):
            return .dessert
        default:
            return .lunch
        }
    }
}

// MARK: - Usage Example in DataManager
extension DataManager {
    func loadRecipesFromAPI() async {
        do {
            let apiRecipes = try await RecipeAPIService.shared.searchHighProteinRecipes()
            
            // Convert API recipes to RecommendationCards
            let newRecommendations = apiRecipes.map { $0.toRecommendationCard() }
            
            // TODO: Cache these in CoreData/SwiftData
            print("✅ Loaded \(newRecommendations.count) recipes from API")
            
        } catch {
            print("❌ Failed to load recipes from API: \(error)")
            // Fallback to local recipes
        }
    }
}