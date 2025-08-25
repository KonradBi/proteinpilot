import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var proteinDailyTarget: Double
    var eatingWindowStart: Date
    var eatingWindowEnd: Date
    var bodyWeight: Double
    var goal: String
    var cookingSkills: String
    var noGosRaw: String?
    @Transient var noGos: [String] {
        get {
            guard let raw = noGosRaw, let data = raw.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            let data = (try? JSONEncoder().encode(newValue)) ?? Data("[]".utf8)
            noGosRaw = String(data: data, encoding: .utf8) ?? "[]"
        }
    }
    var createdAt: Date
    var updatedAt: Date
    
    init(
        proteinDailyTarget: Double,
        eatingWindowStart: Date,
        eatingWindowEnd: Date,
        bodyWeight: Double,
        goal: String = "muscle_building",
        cookingSkills: String = "intermediate",
        noGos: [String] = []
    ) {
        self.id = UUID()
        self.proteinDailyTarget = proteinDailyTarget
        self.eatingWindowStart = eatingWindowStart
        self.eatingWindowEnd = eatingWindowEnd
        self.bodyWeight = bodyWeight
        self.goal = goal
        self.cookingSkills = cookingSkills
        let data = (try? JSONEncoder().encode(noGos)) ?? Data("[]".utf8)
        self.noGosRaw = String(data: data, encoding: .utf8) ?? "[]"
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}