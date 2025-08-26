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
            ProteinBalance.self,
            CachedRecipe.self,
            ProteinStreak.self
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
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            print("✅ User saved to CoreData successfully")
        } catch {
            print("❌ Error saving user: \(error)")
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
    
    // MARK: - Smart Aggregation
    
    /// Get aggregated entries for today (groups same food items together)
    func getAggregatedEntriesForToday() -> [AggregatedEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let entries = getRecentEntries(limit: 200).filter { entry in
            entry.date >= today && entry.date < tomorrow
        }
        
        return aggregateEntries(entries)
    }
    
    /// Get aggregated entries for a specific date
    func getAggregatedEntries(for date: Date) -> [AggregatedEntry] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let entries = getRecentEntries(limit: 200).filter { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }
        
        return aggregateEntries(entries)
    }
    
    /// Aggregate entries by food item
    private func aggregateEntries(_ entries: [ProteinEntry]) -> [AggregatedEntry] {
        // Group by food item ID
        let grouped = Dictionary(grouping: entries) { entry in
            entry.foodItem?.id.uuidString ?? "unknown_\(entry.id.uuidString)"
        }
        
        // Convert to aggregated entries
        return grouped.compactMap { (_, entries) in
            guard let firstEntry = entries.first,
                  let foodItem = firstEntry.foodItem else { return nil }
            
            return AggregatedEntry(foodItem: foodItem, entries: entries)
        }
        .sorted { $0.lastEatenAt > $1.lastEatenAt } // Most recent first
    }
    
    /// Convert planned meal to actual protein entries
    @discardableResult
    func completePlannedMeal(_ meal: PlannedMeal) -> [ProteinEntry] {
        // For now, create a generic entry with estimated protein
        // In the future, this could be more sophisticated based on the meal details
        let entry = addProteinEntry(
            quantity: meal.expectedProtein, // Use protein as quantity for now
            proteinGrams: meal.expectedProtein
        )
        
        meal.status = .completed
        return [entry]
    }
    
    // MARK: - Production Recipe Loading (Cache Only)
    func loadRecommendationsWithCaching() async -> [RecommendationCard] {
        // Production approach: Only use pre-seeded cached recipes (no API calls for users)
        let cachedRecipes = loadCachedRecipes()
        let stats = getCacheStatistics()
        
        print("✅ Loaded \(stats.total) recipes from cache (\(stats.localRecipes) local, \(stats.apiRecipes) pre-seeded)")
        
        // In production, we should always have 200+ pre-seeded recipes
        if stats.total < 100 {
            print("⚠️ Low recipe count (\(stats.total)) - consider running pre-launch seeding")
        }
        
        return cachedRecipes
    }
    
    // MARK: - Recipe API Integration  
    func seedRecipesFromAPI() async {
        await RecipeCacheService.shared.seedDatabaseFromAPI()
    }
    
    func getCachedRecipes() async -> [RecommendationCard] {
        return await RecipeCacheService.shared.loadCachedRecipes()
    }
    
    // MARK: - Streak System Management
    
    func getCurrentStreak() -> ProteinStreak {
        let request = FetchDescriptor<ProteinStreak>()
        do {
            let streaks = try context.fetch(request)
            if let streak = streaks.first {
                return streak
            } else {
                // Create initial streak
                let newStreak = ProteinStreak()
                context.insert(newStreak)
                try context.save()
                return newStreak
            }
        } catch {
            print("Error fetching streak: \(error)")
            return ProteinStreak()
        }
    }
    
    func updateStreakProgress() -> (badges: [StreakBadge], levelUp: ProteinLevel?) {
        guard let user = getCurrentUser() else { return ([], nil) }
        
        let todaysProtein = getTodaysTotalProtein()
        let targetHit = todaysProtein >= user.proteinDailyTarget
        
        let streak = getCurrentStreak()
        let newBadges = streak.updateStreak(
            todayHitTarget: targetHit, 
            todaysProtein: todaysProtein, 
            targetProtein: user.proteinDailyTarget
        )
        
        // Check for level up
        let levelUp = streak.checkForLevelUp()
        
        // Save updated streak
        do {
            try context.save()
        } catch {
            print("Error saving streak: \(error)")
        }
        
        return (badges: newBadges, levelUp: levelUp)
    }
    
    func checkDailyAchievements(entries: [ProteinEntry]) -> [DailyAchievement] {
        var achievements: [DailyAchievement] = []
        let today = Calendar.current.startOfDay(for: Date())
        let streak = getCurrentStreak()
        
        // Reset daily achievements if it's a new day
        let todayString = DateFormatter().string(from: today)
        let lastAchievementDate = streak.todaysDailyAchievements.first?.split(separator: "_").first
        if String(lastAchievementDate ?? "") != todayString {
            streak.todaysDailyAchievements = []
        }
        
        guard let user = getCurrentUser() else { return [] }
        let todaysTotal = getTodaysTotalProtein()
        let target = user.proteinDailyTarget
        let progressPercentage = todaysTotal / target
        
        // INSTANT REWARDS (every protein entry triggers check)
        
        // First entry ever
        if !streak.hasHadFirstEntry && !alreadyAchieved(.firstEntry, streak) {
            achievements.append(.firstEntry)
            streak.hasHadFirstEntry = true
        }
        
        // Daily start (first entry of the day)
        let todaysEntries = entries.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        if todaysEntries.count == 1 && !alreadyAchieved(.dailyStart, streak) {
            achievements.append(.dailyStart)
        }
        
        // Progress milestones (show highest achieved milestone not yet shown today)
        if progressPercentage >= 1.0 && !alreadyAchieved(.goalReached, streak) {
            achievements.append(.goalReached)
        } else if progressPercentage >= 0.75 && !alreadyAchieved(.almostThere, streak) {
            achievements.append(.almostThere)
        } else if progressPercentage >= 0.5 && !alreadyAchieved(.halfwayThere, streak) {
            achievements.append(.halfwayThere)
        } else if progressPercentage >= 0.25 && !alreadyAchieved(.goodProgress, streak) {
            achievements.append(.goodProgress)
        }
        
        // TIME-BASED REWARDS
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Early Bird - protein before 9 AM
        if currentHour < 9 && todaysTotal >= 15 && !alreadyAchieved(.earlyBird, streak) {
            achievements.append(.earlyBird)
        }
        
        // Midnight Warrior - after 22:00
        if currentHour >= 22 && !alreadyAchieved(.midnightWarrior, streak) {
            achievements.append(.midnightWarrior)
        }
        
        // Weekend Warrior
        let dayOfWeek = Calendar.current.component(.weekday, from: today)
        if (dayOfWeek == 1 || dayOfWeek == 7) && todaysTotal >= target && !alreadyAchieved(.weekendWarrior, streak) {
            achievements.append(.weekendWarrior)
        }
        
        // BEHAVIOR REWARDS
        
        // Perfect Day - exactly target hit
        if abs(todaysTotal - target) <= 5 && todaysTotal >= target && !alreadyAchieved(.perfectDay, streak) {
            achievements.append(.perfectDay)
        }
        
        // Power Day - 150%+ of target
        if todaysTotal >= target * 1.5 && !alreadyAchieved(.powerDay, streak) {
            achievements.append(.powerDay)
        }
        
        // Variety - 5+ different protein sources
        let uniqueFoodItems = Set(todaysEntries.compactMap { $0.foodItem?.id })
        if uniqueFoodItems.count >= 5 && !alreadyAchieved(.variety, streak) {
            achievements.append(.variety)
        }
        
        // Comeback Kid - first entry after streak break
        if streak.currentStreak == 1 && streak.bestStreak > 1 && !alreadyAchieved(.comebackKid, streak) {
            achievements.append(.comebackKid)
        }
        
        // Mark achievements as completed for today
        for achievement in achievements {
            let achievementKey = "\(todayString)_\(achievement.rawValue)"
            if !streak.todaysDailyAchievements.contains(achievementKey) {
                streak.todaysDailyAchievements.append(achievementKey)
            }
        }
        
        // Save streak updates
        do {
            try context.save()
        } catch {
            print("Error saving streak achievements: \(error)")
        }
        
        return achievements
    }
    
    private func alreadyAchieved(_ achievement: DailyAchievement, _ streak: ProteinStreak) -> Bool {
        let today = DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        let achievementKey = "\(today)_\(achievement.rawValue)"
        return streak.todaysDailyAchievements.contains(achievementKey)
    }
}