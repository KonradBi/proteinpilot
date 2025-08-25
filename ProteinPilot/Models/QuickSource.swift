import Foundation
import SwiftData

enum QuickSourceType {
    case recent
    case custom
    case favorite
}

struct QuickSource: Identifiable {
    let id = UUID()
    let name: String
    let proteinAmount: Double
    let type: QuickSourceType
    let lastUsed: Date
    let usageCount: Int
    let foodItem: FoodItem?
    
    var displayName: String {
        switch type {
        case .recent:
            return name == "Protein" ? "Schnell-Protein" : name
        case .custom, .favorite:
            return name
        }
    }
    
    var sortPriority: Double {
        let timeFactor = Date().timeIntervalSince(lastUsed) / 86400 // days
        let baseScore = Double(usageCount) * 100
        let timeDecay = max(0, baseScore * (1 - timeFactor * 0.1))
        
        switch type {
        case .favorite: return timeDecay + 1000
        case .custom: return timeDecay + 500  
        case .recent: return timeDecay
        }
    }
}