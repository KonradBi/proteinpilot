import Foundation
import SwiftData

/// Aggregated representation of multiple protein entries for the same food item
/// Used to display "7x Eier (42g)" instead of 7 separate egg entries
class AggregatedEntry: Identifiable {
    let id = UUID()
    let foodItem: FoodItem
    let totalQuantity: Double
    let totalProtein: Double
    let count: Int
    let entries: [ProteinEntry]
    let lastEatenAt: Date
    
    init(foodItem: FoodItem, entries: [ProteinEntry]) {
        self.foodItem = foodItem
        self.entries = entries.sorted { $0.date < $1.date }
        self.totalQuantity = entries.reduce(0) { $0 + $1.quantity }
        self.totalProtein = entries.reduce(0) { $0 + $1.proteinGrams }
        self.count = entries.count
        self.lastEatenAt = entries.max { $0.date < $1.date }?.date ?? Date()
    }
    
    /// Display text for the aggregated entry
    var displayText: String {
        if count == 1 {
            return "\(Int(totalQuantity))g \(foodItem.name)"
        } else {
            return "\(count)x \(foodItem.name)"
        }
    }
    
    /// Protein display text
    var proteinText: String {
        return "\(Int(totalProtein))g"
    }
    
    /// Icon for the food item
    var icon: String {
        return foodItem.emoji ?? "🍽️"
    }
}

/// Planned meal from recommendations (not yet eaten)
class PlannedMeal: Identifiable {
    let id = UUID()
    let title: String
    let expectedProtein: Double
    let scheduledTime: String?
    let source: PlannedMealSource
    var status: PlannedMealStatus
    let icon: String
    
    init(title: String, expectedProtein: Double, scheduledTime: String? = nil, source: PlannedMealSource = .recommendation, icon: String = "🍽️") {
        self.title = title
        self.expectedProtein = expectedProtein
        self.scheduledTime = scheduledTime
        self.source = source
        self.status = .planned
        self.icon = icon
    }
}

enum PlannedMealSource {
    case recommendation  // Added from recommendations carousel
    case manual         // Manually planned by user
}

enum PlannedMealStatus {
    case planned        // Not eaten yet
    case completed      // Eaten (converted to actual protein entries)
}