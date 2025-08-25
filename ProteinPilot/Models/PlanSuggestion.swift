import Foundation
import SwiftData

@Model
final class PlanSuggestion {
    var id: UUID
    var date: Date
    var options: [SuggestionOption]
    var isUsed: Bool
    var createdAt: Date
    
    init(
        date: Date,
        options: [SuggestionOption] = []
    ) {
        self.id = UUID()
        self.date = date
        self.options = options
        self.isUsed = false
        self.createdAt = Date()
    }
}

struct SuggestionOption: Codable {
    let foodItemName: String
    let proteinAmount: Double
    let quantity: Double
    let prepTime: Int
    let reason: String
    
    init(
        foodItemName: String,
        proteinAmount: Double,
        quantity: Double,
        prepTime: Int = 5,
        reason: String = ""
    ) {
        self.foodItemName = foodItemName
        self.proteinAmount = proteinAmount
        self.quantity = quantity
        self.prepTime = prepTime
        self.reason = reason
    }
}