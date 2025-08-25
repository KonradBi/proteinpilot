import Foundation
import SwiftData

@Model
final class ProteinEntry {
    var id: UUID
    var date: Date
    var quantity: Double
    var proteinGrams: Double
    var mealType: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var foodItem: FoodItem?
    
    init(
        date: Date,
        quantity: Double,
        proteinGrams: Double,
        foodItem: FoodItem? = nil,
        mealType: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.quantity = quantity
        self.proteinGrams = proteinGrams
        self.foodItem = foodItem
        self.mealType = mealType
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var displayName: String {
        if let foodItem = foodItem {
            return "\(Int(quantity))g \(foodItem.name)"
        }
        return "Protein: \(Int(proteinGrams))g"
    }
}