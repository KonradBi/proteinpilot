import Foundation
import SwiftData

@Model
final class ProteinBalance {
    var id: UUID
    var date: Date
    var targetProtein: Double
    var consumedProtein: Double
    var rolloverBalance: Double
    var adjustedTarget: Double
    
    init(
        date: Date,
        targetProtein: Double,
        consumedProtein: Double = 0.0,
        rolloverBalance: Double = 0.0
    ) {
        self.id = UUID()
        self.date = date
        self.targetProtein = targetProtein
        self.consumedProtein = consumedProtein
        self.rolloverBalance = rolloverBalance
        self.adjustedTarget = targetProtein
    }
    
    var deficit: Double {
        return adjustedTarget - consumedProtein
    }
    
    var progressPercentage: Double {
        guard adjustedTarget > 0 else { return 0 }
        return min(consumedProtein / adjustedTarget, 1.0)
    }
    
    func updateRollover(alpha: Double = 0.3, maxRollover: Double) {
        let delta = consumedProtein - targetProtein
        let newBalance = max(min(rolloverBalance + delta, maxRollover), -maxRollover)
        rolloverBalance = newBalance
        adjustedTarget = targetProtein - (alpha * rolloverBalance)
    }
}