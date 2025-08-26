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
    var day: String? // YYYY-MM-DD format for easier filtering
    var time: String? // HH:mm format
    var status: EntryStatus?
    
    @Relationship
    var foodItem: FoodItem?
    
    init(
        date: Date,
        quantity: Double,
        proteinGrams: Double,
        foodItem: FoodItem? = nil,
        mealType: String? = nil,
        notes: String? = nil,
        status: EntryStatus = .done
    ) {
        self.id = UUID()
        self.date = date
        self.quantity = quantity
        self.proteinGrams = proteinGrams
        self.foodItem = foodItem
        self.mealType = mealType
        self.notes = notes
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Format day and time
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.day = formatter.string(from: date)
        
        formatter.dateFormat = "HH:mm"
        self.time = formatter.string(from: date)
    }
    
    var displayName: String {
        if let foodItem = foodItem {
            return "\(Int(quantity))g \(foodItem.name)"
        }
        return "Protein: \(Int(proteinGrams))g"
    }
    
    enum EntryStatus: String, Codable, CaseIterable {
        case planned = "planned"
        case done = "done"
        case skipped = "skipped"
    }
}