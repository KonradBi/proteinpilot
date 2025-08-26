import Foundation
import SwiftData

@Model
final class DayPlan {
    var day: Date
    var scheduledItems: [ScheduledItem]
    var macroTotals: MacroTotals
    
    init(day: Date) {
        self.day = Calendar.current.startOfDay(for: day)
        self.scheduledItems = []
        self.macroTotals = MacroTotals()
    }
}

@Model 
final class ScheduledItem {
    var id: UUID
    var type: ItemType
    var recipeId: String?
    var title: String
    var time: String
    var day: Date
    var servings: Double
    var status: ItemStatus
    var proteinGrams: Double?
    var estimatedDurationMin: Int?
    
    init(type: ItemType, title: String, time: String, day: Date, servings: Double = 1.0) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.time = time
        self.day = day
        self.servings = servings
        self.status = .planned
    }
    
    enum ItemType: String, Codable, CaseIterable {
        case meal = "meal"
        case intake = "intake"
        case workout = "workout"
    }
    
    enum ItemStatus: String, Codable, CaseIterable {
        case planned = "planned"
        case done = "done"
        case skipped = "skipped"
    }
}

@Model
final class MacroTotals {
    var proteinGrams: Double
    var goalProteinGrams: Double
    var balanceGrams: Double // for rolling catch-up
    
    init(proteinGrams: Double = 0, goalProteinGrams: Double = 120, balanceGrams: Double = 0) {
        self.proteinGrams = proteinGrams
        self.goalProteinGrams = goalProteinGrams
        self.balanceGrams = balanceGrams
    }
}

@Model
final class RecommendationCard {
    var recipeId: String
    var title: String
    var image: String?
    var durationMin: Int
    var kcal: Int?
    var tags: [String]
    var proteinGrams: Double?
    var priority: Double // for sorting
    var ingredients: [String] // Zutatenliste
    var instructions: String // Kurze Anleitung
    var difficulty: RecipeDifficulty // Schwierigkeitsgrad
    var category: RecipeCategory // Kategorie für bessere Filterung
    
    init(recipeId: String, title: String, durationMin: Int, tags: [String] = [], ingredients: [String] = [], instructions: String = "") {
        self.recipeId = recipeId
        self.title = title
        self.durationMin = durationMin
        self.tags = tags
        self.priority = 1.0
        self.ingredients = ingredients
        self.instructions = instructions
        self.difficulty = .easy
        self.category = .protein_shot
    }
}

enum RecipeDifficulty: String, CaseIterable, Codable {
    case easy = "Einfach"
    case medium = "Mittel" 
    case advanced = "Fortgeschritten"
}

enum RecipeCategory: String, CaseIterable, Codable {
    case protein_shot = "Protein-Shot"
    case breakfast = "Frühstück"
    case lunch = "Mittagessen"
    case dinner = "Abendessen"
    case snack = "Snack"
    case dessert = "Dessert"
    case vegan = "Vegan"
    case vegetarian = "Vegetarisch"
}