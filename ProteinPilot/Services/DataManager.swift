import Foundation
import SwiftData

@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private var container: ModelContainer
    var context: ModelContext
    
    private init() {
        let schema = Schema([
            User.self,
            FoodItem.self,
            ProteinEntry.self,
            PlanSuggestion.self,
            ProteinBalance.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = container.mainContext
        } catch {
            if Self.removeDefaultStore() {
                do {
                    container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    context = container.mainContext
                } catch {
                    fatalError("Could not recreate ModelContainer after reset: \(error)")
                }
            } else {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
    
    private static func removeDefaultStore() -> Bool {
        let fileManager = FileManager.default
        do {
            let appSupport = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let storeURL = appSupport.appendingPathComponent("default.store")
            let shmURL = appSupport.appendingPathComponent("default.store-shm")
            let walURL = appSupport.appendingPathComponent("default.store-wal")
            if fileManager.fileExists(atPath: storeURL.path) {
                try? fileManager.removeItem(at: storeURL)
            }
            if fileManager.fileExists(atPath: shmURL.path) {
                try? fileManager.removeItem(at: shmURL)
            }
            if fileManager.fileExists(atPath: walURL.path) {
                try? fileManager.removeItem(at: walURL)
            }
            return true
        } catch {
            return false
        }
    }
    
    func getCurrentUser() -> User? {
        let request = FetchDescriptor<User>()
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    func createUser(
        proteinTarget: Double,
        eatingStart: Date,
        eatingEnd: Date,
        bodyWeight: Double
    ) {
        let user = User(
            proteinDailyTarget: proteinTarget,
            eatingWindowStart: eatingStart,
            eatingWindowEnd: eatingEnd,
            bodyWeight: bodyWeight
        )
        context.insert(user)
        
        do {
            try context.save()
        } catch {
            print("Error saving user: \(error)")
        }
    }
    
    func getTodaysEntries() -> [ProteinEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let request = FetchDescriptor<ProteinEntry>(
            predicate: #Predicate { entry in
                entry.date >= today && entry.date < tomorrow
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching today's entries: \(error)")
            return []
        }
    }
    
    func getTodaysTotalProtein() -> Double {
        return getTodaysEntries().reduce(0) { $0 + $1.proteinGrams }
    }
    
    @discardableResult
    func addProteinEntry(
        quantity: Double,
        proteinGrams: Double,
        foodItem: FoodItem? = nil,
        mealType: String? = nil
    ) -> ProteinEntry {
        let entry = ProteinEntry(
            date: Date(),
            quantity: quantity,
            proteinGrams: proteinGrams,
            foodItem: foodItem,
            mealType: mealType
        )
        context.insert(entry)
        
        do {
            try context.save()
        } catch {
            print("Error saving protein entry: \(error)")
        }
        return entry
    }
    
    func getRecentEntries(limit: Int = 20) -> [ProteinEntry] {
        var request = FetchDescriptor<ProteinEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent entries: \(error)")
            return []
        }
    }
    
    func createCustomFoodItem(name: String, proteinPer100g: Double, emoji: String? = nil, defaultPortionGrams: Double = 100) -> FoodItem {
        let item = FoodItem(
            name: name,
            emoji: emoji,
            proteinPer100g: proteinPer100g,
            defaultPortionGrams: defaultPortionGrams,
            source: .custom
        )
        context.insert(item)
        do { try context.save() } catch { print("Error saving custom food item: \(error)") }
        return item
    }
    
    func getCustomFoodItems(limit: Int = 50) -> [FoodItem] {
        var request = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        request.fetchLimit = limit * 3
        do {
            let all = try context.fetch(request)
            return Array(all.filter { $0.source == .custom }.prefix(limit))
        } catch { return [] }
    }
    
    func deleteEntry(_ entry: ProteinEntry) {
        context.delete(entry)
        do {
            try context.save()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
    
    // MARK: - Quick Food Management
    
    /// Initialize default quick foods if they don't exist
    func initializeDefaultQuickFoods() {
        let existingTemplateCount = getTemplateFoodItems().count
        
        // Only add defaults if no template foods exist yet
        guard existingTemplateCount == 0 else { 
            print("🔄 Skipping initialization - \(existingTemplateCount) template foods already exist")
            return 
        }
        
        print("🎆 Initializing \(FoodItem.defaultQuickFoods.count) default quick foods...")
        
        for defaultFood in FoodItem.defaultQuickFoods {
            // Create new instances to avoid SwiftData issues
            let newFood = FoodItem(
                name: defaultFood.name,
                emoji: defaultFood.emoji,
                proteinPer100g: defaultFood.proteinPer100g,
                defaultPortionGrams: defaultFood.defaultPortionGrams,
                source: .template
            )
            context.insert(newFood)
            print("  ✅ Added: \(newFood.emoji ?? "❓") \(newFood.name) (\(newFood.proteinPerPortion)g protein)")
        }
        
        do {
            try context.save()
            print("✅ Successfully initialized \(FoodItem.defaultQuickFoods.count) default quick foods")
        } catch {
            print("❌ Error saving default quick foods: \(error)")
        }
    }
    
    /// Get template/default food items
    func getTemplateFoodItems() -> [FoodItem] {
        let request = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            let allFoods = try context.fetch(request)
            return allFoods.filter { $0.source == .template }
        } catch {
            print("Error fetching template foods: \(error)")
            return []
        }
    }
    
    /// Get top quick food items based on usage and recency
    func getQuickFoodItems(limit: Int = 6) -> [FoodItem] {
        // Get template foods (default quick foods)
        let templateFoods = getTemplateFoodItems()
        
        // Get most used custom foods
        let customFoods = getCustomFoodItems(limit: 3)
        
        // Combine and prioritize template foods first
        var quickFoods: [FoodItem] = []
        quickFoods.append(contentsOf: templateFoods.prefix(limit))
        
        // Fill remaining slots with custom foods
        let remainingSlots = max(0, limit - quickFoods.count)
        if remainingSlots > 0 {
            quickFoods.append(contentsOf: customFoods.prefix(remainingSlots))
        }
        
        return Array(quickFoods.prefix(limit))
    }
    
    /// Add protein from quick food (handles portion calculation)
    @discardableResult
    func addProteinFromQuickFood(
        _ food: FoodItem,
        portions: Double = 1.0
    ) -> ProteinEntry {
        let totalQuantity = food.defaultPortionGrams * portions
        let totalProtein = food.proteinPerPortion * portions
        
        return addProteinEntry(
            quantity: totalQuantity,
            proteinGrams: totalProtein,
            foodItem: food
        )
    }
    
    func getTodaysBalance() -> ProteinBalance? {
        let today = Calendar.current.startOfDay(for: Date())
        
        let request = FetchDescriptor<ProteinBalance>(
            predicate: #Predicate { balance in
                balance.date == today
            }
        )
        
        do {
            let balances = try context.fetch(request)
            return balances.first
        } catch {
            print("Error fetching today's balance: \(error)")
            return nil
        }
    }
    
    func updateTodaysBalance() {
        guard let user = getCurrentUser() else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let todaysProtein = getTodaysTotalProtein()
        
        var balance = getTodaysBalance()
        
        if balance == nil {
            balance = ProteinBalance(
                date: today,
                targetProtein: user.proteinDailyTarget,
                consumedProtein: todaysProtein
            )
            context.insert(balance!)
        } else {
            balance?.consumedProtein = todaysProtein
        }
        
        balance?.updateRollover(maxRollover: user.proteinDailyTarget)
        
        do {
            try context.save()
        } catch {
            print("Error updating balance: \(error)")
        }
    }
    
    func generateAdaptiveMealSuggestions() async throws -> [AdaptiveMealSuggestion] {
        // Mock implementation for now - in real app would integrate with AI service
        return [
            AdaptiveMealSuggestion(
                name: "Protein-Smoothie",
                proteinAmount: 25,
                prepTimeMinutes: 2,
                reason: "Schneller Whey-Shake mit Banane",
                context: "⚡ Schnell",
                priority: 90,
                urgency: .urgent,
                situation: .onTheGo
            ),
            AdaptiveMealSuggestion(
                name: "Greek Yogurt Bowl",
                proteinAmount: 18,
                prepTimeMinutes: 3,
                reason: "Griechischer Joghurt mit Nüssen",
                context: "🍽️ Normal",
                priority: 80,
                urgency: .normal,
                situation: .home
            ),
            AdaptiveMealSuggestion(
                name: "Hühnerbrust Wrap",
                proteinAmount: 35,
                prepTimeMinutes: 8,
                reason: "Gebratene Hühnerbrust im Wrap",
                context: "🏠 Zuhause kochen",
                priority: 70,
                urgency: .normal,
                situation: .home
            ),
            AdaptiveMealSuggestion(
                name: "Protein Riegel",
                proteinAmount: 20,
                prepTimeMinutes: 1,
                reason: "Auspacken und essen",
                context: "🎒 Für unterwegs",
                priority: 60,
                urgency: .normal,
                situation: .onTheGo
            )
        ]
    }
}