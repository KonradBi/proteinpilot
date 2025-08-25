import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var emoji: String?
    var proteinPer100g: Double
    var defaultPortionGrams: Double
    var source: FoodSource
    var barcode: String?
    var brand: String?
    var category: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \ProteinEntry.foodItem)
    var entries: [ProteinEntry] = []
    
    init(
        name: String,
        emoji: String? = nil,
        proteinPer100g: Double,
        defaultPortionGrams: Double = 100,
        source: FoodSource,
        barcode: String? = nil,
        brand: String? = nil,
        category: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.proteinPer100g = proteinPer100g
        self.defaultPortionGrams = defaultPortionGrams
        self.source = source
        self.barcode = barcode
        self.brand = brand
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum FoodSource: String, CaseIterable, Codable {
    case scan = "scan"
    case template = "template"
    case custom = "custom"
    case api = "api"
}

// MARK: - Default Food Items
extension FoodItem {
    static let defaultQuickFoods: [FoodItem] = [
        FoodItem(
            name: "Ei",
            emoji: "🥚",
            proteinPer100g: 13.0,
            defaultPortionGrams: 50,  // 1 Ei ≈ 50g = 6.5g Protein
            source: .template
        ),
        FoodItem(
            name: "Quark",
            emoji: "🧀",
            proteinPer100g: 12.0,
            defaultPortionGrams: 100, // 100g = 12g Protein
            source: .template
        ),
        FoodItem(
            name: "Hähnchen",
            emoji: "🐔",
            proteinPer100g: 23.0,
            defaultPortionGrams: 100, // 100g = 23g Protein
            source: .template
        ),
        FoodItem(
            name: "Thunfisch",
            emoji: "🐟",
            proteinPer100g: 25.0,
            defaultPortionGrams: 80,  // 1 Dose ≈ 80g = 20g Protein
            source: .template
        ),
        FoodItem(
            name: "Proteinshake",
            emoji: "🥛",
            proteinPer100g: 80.0,
            defaultPortionGrams: 30,  // 1 Scoop ≈ 30g = 24g Protein
            source: .template
        ),
        FoodItem(
            name: "Linsen",
            emoji: "🫘",
            proteinPer100g: 9.0,
            defaultPortionGrams: 100, // 100g = 9g Protein
            source: .template
        )
    ]
    
    /// Calculated protein per default portion
    var proteinPerPortion: Double {
        (proteinPer100g * defaultPortionGrams) / 100.0
    }
}