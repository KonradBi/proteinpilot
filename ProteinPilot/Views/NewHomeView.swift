import SwiftUI

struct NewHomeView: View {
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var calendarService = CalendarService.shared
    
    // State for selected date context
    @State private var selectedDate = Date()
    @State private var todaysProtein: Double = 0
    @State private var proteinTarget: Double = 120
    
    // Sheet presentations
    @State private var showingAddEntry = false
    @State private var showingCamera = false
    @State private var showingBarcodeScanner = false
    @State private var showingPlanBottomSheet = false
    @State private var showingRecipeDetail = false
    @State private var selectedRecipe: RecommendationCard?
    
    // Undo functionality
    @State private var lastAddedEntry: ProteinEntry?
    @State private var showUndoBanner = false
    
    // Data for components
    @State private var todaysEntries: [ProteinEntry] = []
    @State private var aggregatedEntries: [AggregatedEntry] = []
    @State private var plannedMeals: [PlannedMeal] = []
    @State private var scheduledItems: [ScheduledItem] = []
    @State private var recommendations: [RecommendationCard] = []
    @State private var quickFoodItems: [FoodItem] = []
    
    // MARK: - Streak System
    @State private var currentStreak: ProteinStreak?
    @State private var showingStreakCelebration = false
    @State private var celebrationBadge: StreakBadge?
    @State private var showingDailyAchievement = false
    @State private var dailyAchievement: DailyAchievement?
    @State private var showingWelcomeCelebration = false
    @State private var showingLevelUpCelebration = false
    @State private var levelUpLevel: ProteinLevel?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with avatar and date
                    headerSection
                    
                    // Protein Ring
                    ProteinRingView(
                        currentProtein: todaysProtein,
                        targetProtein: proteinTarget,
                        streakData: currentStreak,
                        onRingTapped: {
                            // TODO: Show macro details modal
                            print("Ring tapped - show macro details")
                        }
                    )
                    
                    // Input Method Buttons
                    InputMethodButtons(
                        onCameraPressed: { showingCamera = true },
                        onBarcodePressed: { showingBarcodeScanner = true },
                        onVoicePressed: handleVoiceInput,
                        onManualPressed: { showingAddEntry = true }
                    )
                    
                    // Quick Food Chips
                    if !quickFoodItems.isEmpty {
                        quickFoodChipsSection
                    }
                    
                    // Week Strip Calendar
                    WeekStripCalendar(
                        selectedDate: $selectedDate,
                        onDateSelected: handleDateSelection,
                        onLongPress: handleDateLongPress
                    )
                    
                    // Recommendations Carousel
                    RecommendationsCarousel(
                        recommendations: recommendations,
                        selectedDate: selectedDate,
                        onAddToPlan: handleAddToPlan,
                        onCardTapped: handleRecommendationTapped
                    )
                    
                    // Today's Plan List
                    TodayPlanList(
                        plannedMeals: plannedMeals,
                        aggregatedEntries: aggregatedEntries,
                        onPlannedMealComplete: handlePlannedMealComplete,
                        onAggregatedEntryEdit: handleAggregatedEntryEdit,
                        onAggregatedEntryDelete: handleAggregatedEntryDelete
                    )
                    
                }
                .padding(.vertical, 16)
            }
            .toolbar(.hidden, for: .navigationBar)
            .scrollIndicators(.hidden)
            .background(homeBackground)
            .onAppear(perform: loadInitialData)
            .onChange(of: selectedDate) { _, newDate in
                loadDataForDate(newDate)
            }
            // MARK: - Celebration Overlays (Priority Order)
            .overlay {
                // Priority 1: Level Up Celebration (most important)
                if showingLevelUpCelebration, let level = levelUpLevel {
                    LevelUpCelebrationView(
                        newLevel: level,
                        isVisible: showingLevelUpCelebration
                    ) {
                        showingLevelUpCelebration = false
                        levelUpLevel = nil
                    }
                }
                
                // Priority 2: Welcome Celebration (first-time users)
                if showingWelcomeCelebration && !showingLevelUpCelebration {
                    WelcomeCelebrationView(
                        isVisible: showingWelcomeCelebration
                    ) {
                        showingWelcomeCelebration = false
                    }
                }
                
                // Priority 3: Streak Badge Celebration
                if showingStreakCelebration, let badge = celebrationBadge, !showingLevelUpCelebration && !showingWelcomeCelebration {
                    StreakCelebrationView(
                        badge: badge,
                        isVisible: showingStreakCelebration
                    ) {
                        showingStreakCelebration = false
                        celebrationBadge = nil
                    }
                }
                
                // Priority 4: Daily Achievement - Progress Milestones (Mini Celebration)
                if showingDailyAchievement, 
                   let achievement = dailyAchievement,
                   [.goodProgress, .halfwayThere, .almostThere].contains(achievement),
                   !showingLevelUpCelebration && !showingWelcomeCelebration && !showingStreakCelebration {
                    MiniAchievementCelebration(
                        achievement: achievement,
                        isVisible: showingDailyAchievement
                    ) {
                        showingDailyAchievement = false
                        dailyAchievement = nil
                    }
                }
                
                // Priority 5: Daily Achievement - Major Achievements (Full Toast)
                if showingDailyAchievement,
                   let achievement = dailyAchievement,
                   ![.goodProgress, .halfwayThere, .almostThere].contains(achievement),
                   !showingLevelUpCelebration && !showingWelcomeCelebration && !showingStreakCelebration {
                    DailyAchievementToast(
                        achievement: achievement,
                        isVisible: showingDailyAchievement
                    ) {
                        showingDailyAchievement = false
                        dailyAchievement = nil
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showUndoBanner, let entry = lastAddedEntry {
                undoBanner(entry: entry)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView(initialTab: 0)
                .onDisappear {
                    refreshCurrentData()
                }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { result in
                handleCameraResult(result)
                showingCamera = false
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeView { result in
                handleBarcodeResult(result)
                showingBarcodeScanner = false
            }
        }
        .sheet(isPresented: $showingPlanBottomSheet) {
            planBottomSheet
        }
        .sheet(isPresented: $showingRecipeDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe)
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ProteinPilot")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(proteinGradient)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .animation(.easeInOut(duration: 0.2), value: selectedDate)
            }
            
            Spacer()
            
            // Profile Avatar Button
            Button(action: handleProfileTapped) {
                ZStack {
                    Circle()
                        .fill(proteinGradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quick Add Chips (Removed - replaced by modern input methods above)
    
    // MARK: - Background
    private var homeBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.05, blue: 0.05),  // Deep red
                Color(red: 0.15, green: 0.08, blue: 0.02), // Red-brown
                Color(red: 0.18, green: 0.12, blue: 0.03)  // Warm brown
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Gradients
    private var proteinGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0),   // Bright yellow
                Color(red: 1.0, green: 0.65, blue: 0.0),   // Orange-yellow
                Color(red: 0.9, green: 0.2, blue: 0.1)     // Red-orange
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Undo Banner
    private func undoBanner(entry: ProteinEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text("\(Int(entry.proteinGrams))g hinzugefügt")
                .font(.subheadline)
            Spacer()
            Button("Rückgängig") {
                withAnimation {
                    dataManager.deleteEntry(entry)
                    showUndoBanner = false
                    refreshCurrentData()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 6)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Bottom Sheet
    private var planBottomSheet: some View {
        VStack(spacing: 20) {
            Text("Eintrag planen")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .padding(.top, 20)
            
            // TODO: Add form for planning entries
            Text("Planungs-Interface kommt hier hin")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Quick Food Chips Section
    private var quickFoodChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    // Subtle glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.6),
                                    Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 12
                            )
                        )
                        .frame(width: 24, height: 24)
                        .blur(radius: 6)
                    
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.9, blue: 0.0),
                                    Color(red: 1.0, green: 0.6, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(.subheadline, weight: .bold))
                        .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                Text("Schnell antippen")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("Mehrfach tippen → Anzahl")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                    )
            }
            
            // Grid layout for better space utilization
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 12) {
                ForEach(Array(quickFoodItems.prefix(6)), id: \.id) { food in
                    QuickFoodChip(food: food) { proteinDelta in
                        handleQuickFoodAdd(food: food, proteinDelta: proteinDelta)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Action Handlers
    private func loadInitialData() {
        refreshCurrentData()
        loadDataForDate(selectedDate)
        loadRecommendations()
        loadQuickFoodItems()
        loadStreakData()
        
        // Setup smart notifications
        setupSmartNotifications()
    }
    
    private func setupSmartNotifications() {
        // Trigger smart reminders when app launches
        NotificationService.shared.triggerSmartReminder()
        
        // Also trigger when protein data changes significantly
        let currentProtein = dataManager.getTodaysTotalProtein()
        if let user = dataManager.getCurrentUser() {
            let remainingProtein = user.proteinDailyTarget - currentProtein
            
            // If user has less than 80% of their daily goal with less than 3 hours in eating window
            let progressPercentage = currentProtein / user.proteinDailyTarget
            let now = Date()
            let timeUntilWindowEnd = user.eatingWindowEnd.timeIntervalSince(now)
            
            if progressPercentage < 0.8 && timeUntilWindowEnd < 3 * 60 * 60 && timeUntilWindowEnd > 0 {
                NotificationService.shared.scheduleSmartReminder(for: user, remainingProtein: remainingProtein)
            }
        }
    }
    
    private func refreshCurrentData() {
        todaysProtein = dataManager.getTodaysTotalProtein()
        if let user = dataManager.getCurrentUser() {
            proteinTarget = user.proteinDailyTarget
        }
        dataManager.updateTodaysBalance()
    }
    
    private func loadDataForDate(_ date: Date) {
        // Load entries for selected date
        let calendar = Calendar.current
        let entries = dataManager.getRecentEntries(limit: 100)
        todaysEntries = entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
        
        // Get aggregated entries for the selected date
        if calendar.isDateInToday(date) {
            aggregatedEntries = dataManager.getAggregatedEntriesForToday()
        } else {
            aggregatedEntries = dataManager.getAggregatedEntries(for: date)
        }
        
        // Load planned meals (mock for now - would come from recommendations added to plan)
        plannedMeals = loadPlannedMealsForDate(date)
        
        // Load scheduled items for selected date (mock data for now)
        scheduledItems = mockScheduledItems(for: date)
        
        // Update protein data if today is selected
        if calendar.isDateInToday(date) {
            refreshCurrentData()
        } else {
            // Calculate protein for the selected day from entries
            todaysProtein = todaysEntries.reduce(0) { $0 + $1.proteinGrams }
        }
    }
    
    private func loadRecommendations() {
        // Use hybrid caching strategy: Load from cache + API seeding
        Task {
            await loadRecommendationsWithCaching()
        }
        
        // Local fallback recipes (loads immediately while caching loads)
        recommendations = [
            // High-Protein Shots & Quick Options (1-3 Min)
            RecommendationCard(
                recipeId: "shot1", 
                title: "Protein-Shot Milchreis", 
                durationMin: 2, 
                tags: ["⚡ Blitz", "🥛 Instant", "💪 35g"],
                ingredients: ["200ml Milch", "30g Proteinpulver (Vanille)", "2 EL Milchreis (gekocht)", "1 TL Zimt", "Süßungsmittel nach Geschmack"],
                instructions: "Milch erwärmen, Proteinpulver einrühren, Milchreis hinzufügen, mit Zimt würzen."
            ),
            
            RecommendationCard(
                recipeId: "shot2", 
                title: "Skyr Power-Bomb", 
                durationMin: 1, 
                tags: ["⚡ Instant", "🧊 Kalt", "💪 30g"],
                ingredients: ["200g Skyr natur", "1 EL Mandelmus", "1 TL Honig", "10g Mandeln gehackt", "Beeren nach Wahl"],
                instructions: "Alle Zutaten verrühren, mit Beeren und Mandeln toppen."
            ),
            
            RecommendationCard(
                recipeId: "shot3", 
                title: "Whey-Shake Deluxe", 
                durationMin: 1, 
                tags: ["⚡ Turbo", "🥤 Shake", "💪 40g"],
                ingredients: ["300ml kalte Milch", "40g Proteinpulver", "1 Banane", "1 EL Erdnussbutter", "Eiswürfel"],
                instructions: "Alle Zutaten in Mixer geben, 30 Sekunden mixen, sofort trinken."
            ),
            
            RecommendationCard(
                recipeId: "shot4", 
                title: "Quark-Beeren Blitz", 
                durationMin: 2, 
                tags: ["🍓 Süß", "🧊 Frisch", "💪 28g"],
                ingredients: ["250g Magerquark", "100g gemischte Beeren", "1 EL Haferflocken", "1 TL Vanilleextrakt", "Stevia nach Geschmack"],
                instructions: "Quark cremig rühren, Vanille hinzufügen, mit Beeren und Haferflocken servieren."
            ),
            
            // Creative Breakfast Options (3-8 Min)
            RecommendationCard(
                recipeId: "break1", 
                title: "Protein-Müsli Crunch", 
                durationMin: 3, 
                tags: ["🌅 Morgens", "🥣 Müsli", "💪 28g"],
                ingredients: ["50g Haferflocken", "200ml Milch", "20g Proteinpulver", "1 EL Nüsse gemischt", "1 Apfel gewürfelt", "1 TL Zimt"],
                instructions: "Haferflocken mit warmer Milch übergießen, Proteinpulver einrühren, mit Apfel und Nüssen toppen."
            ),
            
            RecommendationCard(
                recipeId: "break2", 
                title: "Eiweiss-Pancakes XXL", 
                durationMin: 8, 
                tags: ["🥞 Fluffig", "🔥 Heiß", "💪 32g"],
                ingredients: ["3 Eier", "50g Haferflocken", "1 Banane", "20g Proteinpulver", "1 TL Backpulver", "Zimt", "Kokosöl zum Braten"],
                instructions: "Alle trockenen Zutaten mischen, Eier und Banane pürieren, vermengen, in der Pfanne goldbraun braten."
            ),
            
            RecommendationCard(
                recipeId: "break3", 
                title: "Overnight Oats Boost", 
                durationMin: 1, 
                tags: ["🌙 Vorbereitet", "🧊 Kalt", "💪 35g"],
                ingredients: ["60g Haferflocken", "200ml Milch", "30g Proteinpulver", "2 EL Chiasamen", "1 EL Nussmus", "Früchte nach Wahl"],
                instructions: "Am Vorabend alle Zutaten mischen, über Nacht quellen lassen, morgens mit Früchten servieren."
            ),
            
            // Savory Power Options (5-15 Min)
            RecommendationCard(
                recipeId: "sav1", 
                title: "Hähnchen-Wrap Express", 
                durationMin: 6, 
                tags: ["🌯 Herzhaft", "🔥 Warm", "💪 38g"],
                ingredients: ["1 Vollkorn-Tortilla", "150g Hühnerbrust (gekocht)", "50g Hüttenkäse", "Salat", "Tomate", "Gurke", "Kräuter"],
                instructions: "Hühnchen anbraten, Tortilla erwärmen, mit Hüttenkäse bestreichen, Hähnchen und Gemüse einrollen."
            ),
            
            RecommendationCard(
                recipeId: "sav2", 
                title: "Thunfisch Power-Bowl", 
                durationMin: 4, 
                tags: ["🐟 Omega-3", "🥗 Frisch", "💪 42g"],
                ingredients: ["1 Dose Thunfisch (im eigenen Saft)", "200g Hüttenkäse", "1 Avocado", "Kirschtomaten", "Gurke", "Rucola", "Olivenöl", "Zitrone"],
                instructions: "Gemüse schneiden, Thunfisch abtropfen, alles in Schüssel anrichten, mit Zitrone-Öl-Dressing würzen."
            ),
            
            RecommendationCard(
                recipeId: "sav3", 
                title: "Linsen-Curry Turbo", 
                durationMin: 12, 
                tags: ["🌱 Vegan", "🌶️ Würzig", "💪 32g"],
                ingredients: ["200g rote Linsen", "400ml Kokosmilch", "1 Zwiebel", "2 Knoblauchzehen", "Currypulver", "Kurkuma", "Spinat", "Koriander"],
                instructions: "Zwiebel und Knoblauch anbraten, Linsen und Gewürze hinzufügen, mit Kokosmilch ablöschen, köcheln lassen."
            ),
            
            RecommendationCard(
                recipeId: "sav4", 
                title: "Rührei Deluxe 3.0", 
                durationMin: 5, 
                tags: ["🥚 Klassiker", "🧈 Cremig", "💪 30g"],
                ingredients: ["4 Eier", "50ml Milch", "50g Hüttenkäse", "Schnittlauch", "Butter", "Salz", "Pfeffer"],
                instructions: "Eier verquirlen, Milch hinzufügen, in Butter cremig braten, Hüttenkäse einrühren, mit Schnittlauch garnieren."
            ),
            
            // Creative Snacks & Desserts (2-10 Min)
            RecommendationCard(
                recipeId: "snack1", 
                title: "Protein-Pudding Schoko", 
                durationMin: 3, 
                tags: ["🍫 Süß", "🍮 Dessert", "💪 22g"],
                ingredients: ["200g Magerquark", "20g Proteinpulver Schokolade", "1 EL Kakao", "Süßungsmittel", "Dunkle Schokolade (geraspelt)"],
                instructions: "Quark mit Proteinpulver und Kakao verrühren, süßen, mit Schokoraspeln garnieren, kalt servieren."
            ),
            
            RecommendationCard(
                recipeId: "snack2", 
                title: "Nuss-Butter Energy Balls", 
                durationMin: 8, 
                tags: ["🌱 Vegan", "⚡ Energie", "💪 18g"],
                ingredients: ["100g Mandeln", "50g Datteln", "2 EL Mandelbutter", "1 EL Chiasamen", "1 EL Kakao", "Kokosraspel"],
                instructions: "Mandeln und Datteln mixen, Mandelbutter und Kakao hinzufügen, zu Bällen formen, in Kokos wälzen."
            ),
            
            RecommendationCard(
                recipeId: "snack3", 
                title: "Käse-Schinken Röllchen", 
                durationMin: 2, 
                tags: ["🧀 Low-Carb", "🥓 Herzhaft", "💪 25g"],
                ingredients: ["6 Scheiben magerer Schinken", "100g Hüttenkäse", "6 Scheiben Gurke", "Kresse", "Pfeffer"],
                instructions: "Schinken ausbreiten, mit Hüttenkäse bestreichen, Gurke darauf legen, einrollen, mit Kresse garnieren."
            ),
            
            // Innovative Combos (10-20 Min)
            RecommendationCard(
                recipeId: "combo1", 
                title: "Lachs-Avocado Power Plate", 
                durationMin: 15, 
                tags: ["🐟 Gourmet", "🥑 Gesund", "💪 45g"],
                ingredients: ["150g Lachsfilet", "1 Avocado", "150g Hüttenkäse", "Quinoa (gekocht)", "Babyspinat", "Zitrone", "Olivenöl", "Dill"],
                instructions: "Lachs braten, Avocado schneiden, Quinoa erwärmen, alles auf Teller anrichten, mit Kräutern würzen."
            ),
            
            RecommendationCard(
                recipeId: "combo2", 
                title: "Bohnen-Chili Protein", 
                durationMin: 18, 
                tags: ["🌱 Vegan", "🌶️ Scharf", "💪 38g"],
                ingredients: ["400g gemischte Bohnen", "200ml Gemüsebrühe", "1 Zwiebel", "Paprika", "Chilipulver", "Kreuzkümmel", "Tomatenmark", "Koriander"],
                instructions: "Gemüse anbraten, Bohnen hinzufügen, mit Brühe ablöschen, Gewürze einrühren, köcheln lassen."
            ),
            
            RecommendationCard(
                recipeId: "combo3", 
                title: "Quinoa-Garnelen Bowl", 
                durationMin: 20, 
                tags: ["🦐 Meeresfrüchte", "🌾 Superfood", "💪 48g"],
                ingredients: ["200g Garnelen", "150g Quinoa", "Edamame", "Rotkohl", "Karotten", "Sesam", "Sojasauce", "Limette", "Ingwer"],
                instructions: "Quinoa kochen, Garnelen anbraten, Gemüse schneiden, Bowl anrichten, mit Sesam-Dressing servieren."
            )
        ]
        
        // Set realistic protein values based on meal type
        let proteinValues = [
            // Protein shots: 28-42g
            ("shot1", 35.0), ("shot2", 30.0), ("shot3", 40.0), ("shot4", 28.0),
            // Breakfast: 25-35g
            ("break1", 28.0), ("break2", 32.0), ("break3", 35.0),
            // Savory: 30-45g
            ("sav1", 38.0), ("sav2", 42.0), ("sav3", 32.0), ("sav4", 30.0),
            // Snacks: 15-25g
            ("snack1", 22.0), ("snack2", 18.0), ("snack3", 25.0),
            // Combos: 35-50g
            ("combo1", 45.0), ("combo2", 38.0), ("combo3", 48.0)
        ]
        
        // Assign protein values, calories and categories
        for recommendation in recommendations {
            if let proteinValue = proteinValues.first(where: { $0.0 == recommendation.recipeId })?.1 {
                recommendation.proteinGrams = proteinValue
                recommendation.kcal = Int(proteinValue * 8.5 + Double.random(in: 50...150)) // Realistic cal estimate
            } else {
                recommendation.proteinGrams = Double.random(in: 20...40)
                recommendation.kcal = Int.random(in: 200...500)
            }
            
            // Set categories and difficulty
            switch recommendation.recipeId.prefix(4) {
            case "shot":
                recommendation.category = .protein_shot
                recommendation.difficulty = .easy
            case "brea":
                recommendation.category = .breakfast
                recommendation.difficulty = .easy
            case "sav1", "sav2":
                recommendation.category = .lunch
                recommendation.difficulty = .easy
            case "sav3", "sav4":
                recommendation.category = .dinner
                recommendation.difficulty = .medium
            case "snac":
                recommendation.category = .snack
                recommendation.difficulty = .easy
            case "comb":
                recommendation.category = .dinner
                recommendation.difficulty = .medium
            default:
                recommendation.category = .protein_shot
                recommendation.difficulty = .easy
            }
            
            // Set vegan/vegetarian categories for specific recipes
            if recommendation.tags.contains("🌱 Vegan") {
                recommendation.category = .vegan
            } else if ["break2", "break3", "snack1", "snack2", "sav4"].contains(recommendation.recipeId) {
                recommendation.category = .vegetarian
            }
        }
    }
    
    private func mockScheduledItems(for date: Date) -> [ScheduledItem] {
        // Return mock scheduled items - in real app this would come from data manager
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        // Different mock data for different days to show calendar is working
        switch dayOfWeek {
        case 1: // Sunday
            return [] // Rest day
        case 2: // Monday
            let item1 = ScheduledItem(type: .meal, title: "Protein Shake", time: "08:00", day: date)
            item1.status = .planned
            let item2 = ScheduledItem(type: .meal, title: "Hühnerbrust Mittag", time: "12:30", day: date)
            item2.status = .planned
            return [item1, item2]
        case 3: // Tuesday
            let item1 = ScheduledItem(type: .meal, title: "Griechischer Joghurt", time: "07:30", day: date)
            item1.status = .done
            let item2 = ScheduledItem(type: .meal, title: "Fisch Abendessen", time: "19:00", day: date)
            item2.status = .planned
            return [item1, item2]
        default:
            let item = ScheduledItem(type: .meal, title: "Tagesziel Protein", time: "09:00", day: date)
            item.status = .planned
            return [item]
        }
    }
    
    private func handleDateSelection(_ date: Date) {
        selectedDate = date
        loadDataForDate(date)
        
        // Provide haptic feedback for date selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleDateLongPress(_ date: Date) {
        selectedDate = date
        showingPlanBottomSheet = true
    }
    
    private func handleVoiceInput() {
        // TODO: Implement voice input with Whisper
        print("Voice input tapped")
    }
    
    // Quick Food Add removed - using modern input methods instead
    
    private func handleAddToPlan(_ recommendation: RecommendationCard, date: Date) {
        // Create a planned meal from the recommendation
        let plannedMeal = PlannedMeal(
            title: recommendation.title,
            expectedProtein: recommendation.proteinGrams ?? 25.0, // Default protein amount
            scheduledTime: nil,
            source: .recommendation,
            icon: "🍽️"
        )
        
        // Add to planned meals (in real app, would save to database)
        plannedMeals.append(plannedMeal)
        
        // Refresh the view
        loadDataForDate(selectedDate)
    }
    
    private func handleRecommendationTapped(_ recommendation: RecommendationCard) {
        selectedRecipe = recommendation
        showingRecipeDetail = true
    }
    
    // MARK: - API Integration
    private func loadRecommendationsWithCaching() async {
        // Use the new hybrid caching approach from DataManager
        let cachedRecipes = await DataManager.shared.loadRecommendationsWithCaching()
        
        // Update UI on main thread
        await MainActor.run {
            // Use cached recipes (includes both API and local recipes)
            if !cachedRecipes.isEmpty {
                self.recommendations = cachedRecipes
                print("✅ Loaded \(cachedRecipes.count) cached recipes")
            }
            // If no cached recipes, keep the local fallback that was already set
        }
    }
    
    private func handlePlannedMealComplete(_ meal: PlannedMeal) {
        // Convert planned meal to actual protein entries
        let entries = dataManager.completePlannedMeal(meal)
        
        if let entry = entries.first {
            lastAddedEntry = entry
            showUndo()
        }
        
        // Remove from planned meals
        plannedMeals.removeAll { $0.id == meal.id }
        
        // Update streak and check for achievements
        checkStreakAndAchievements()
        
        refreshCurrentData()
        loadDataForDate(selectedDate)
    }
    
    // MARK: - Streak System Functions
    
    private func loadStreakData() {
        currentStreak = dataManager.getCurrentStreak()
    }
    
    private func checkStreakAndAchievements() {
        // Update streak progress and check for level up
        let streakResult = dataManager.updateStreakProgress()
        
        // Priority 1: Level Up (most important celebration)
        if let newLevel = streakResult.levelUp {
            levelUpLevel = newLevel
            showingLevelUpCelebration = true
            // Refresh streak data and return - level up trumps other celebrations
            loadStreakData()
            return
        }
        
        // Priority 2: New streak badges
        if let newBadge = streakResult.badges.first {
            celebrationBadge = newBadge
            showingStreakCelebration = true
            // Continue to check daily achievements
        }
        
        // Priority 3: Daily achievements
        let todaysEntries = dataManager.getTodaysEntries()
        let dailyAchievements = dataManager.checkDailyAchievements(entries: todaysEntries)
        
        // Handle special first entry welcome
        if let firstAchievement = dailyAchievements.first(where: { $0 == .firstEntry }) {
            showingWelcomeCelebration = true
            // Refresh streak data
            loadStreakData()
            return // Show welcome instead of regular achievement
        }
        
        // Show achievement toast for other achievements (only if no streak celebration)
        if let achievement = dailyAchievements.first, !showingStreakCelebration {
            // Use mini celebration for progress milestones
            if [.goodProgress, .halfwayThere, .almostThere].contains(achievement) {
                // Show mini celebration instead of full toast
                dailyAchievement = achievement
                showingDailyAchievement = true
            } else {
                // Show full toast for major achievements
                dailyAchievement = achievement
                showingDailyAchievement = true
            }
        }
        
        // Refresh streak data
        loadStreakData()
    }
    
    private func handleAggregatedEntryEdit(_ aggregatedEntry: AggregatedEntry) {
        // TODO: Show edit modal for aggregated entry
        print("Edit aggregated entry: \(aggregatedEntry.displayText)")
    }
    
    private func handleAggregatedEntryDelete(_ aggregatedEntry: AggregatedEntry) {
        withAnimation {
            // Delete all entries in the aggregated entry
            for entry in aggregatedEntry.entries {
                dataManager.deleteEntry(entry)
            }
            refreshCurrentData()
            loadDataForDate(selectedDate)
        }
    }
    
    private func handleItemStatusChange(_ item: ScheduledItem, newStatus: ScheduledItem.ItemStatus) {
        item.status = newStatus
        loadDataForDate(selectedDate)
    }
    
    private func loadPlannedMealsForDate(_ date: Date) -> [PlannedMeal] {
        // Mock planned meals for now - in real app would load from database
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            // Only show planned meals for today
            return plannedMeals.filter { $0.status == .planned }
        }
        return [] // No planned meals for past/future dates in this mock
    }
    
    
    private func handleProfileTapped() {
        // TODO: Navigate to profile/settings
        print("Profile tapped")
    }
    
    private func handleCameraResult(_ result: CameraResult) {
        switch result {
        case .success(let nutritionData):
            // Create or find food item for scanned product
            var foodItem: FoodItem? = nil
            
            if let foodName = nutritionData.foodName {
                // Create a food item for the scanned product
                let proteinPer100g = (nutritionData.protein / nutritionData.quantity) * 100
                foodItem = dataManager.createCustomFoodItem(
                    name: foodName,
                    proteinPer100g: proteinPer100g,
                    emoji: "📷", // Camera icon to show it was scanned
                    defaultPortionGrams: nutritionData.quantity
                )
            }
            
            // Add protein entry from camera result
            let entry = dataManager.addProteinEntry(
                quantity: nutritionData.quantity,
                proteinGrams: nutritionData.protein,
                foodItem: foodItem
            )
            lastAddedEntry = entry
            showUndo()
            
            // Check for streak and achievements
            checkStreakAndAchievements()
            
            refreshCurrentData()
            loadDataForDate(selectedDate)
            
        case .failure(let error):
            print("Camera error: \(error)")
            // Could show error alert here
        }
    }
    
    private func handleBarcodeResult(_ result: BarcodeResult) {
        switch result {
        case .success(let barcodeData):
            // Create or find food item for scanned barcode
            let proteinPer100g = (barcodeData.protein / barcodeData.quantity) * 100
            let foodItem = dataManager.createCustomFoodItem(
                name: barcodeData.foodName ?? "Gescanntes Produkt",
                proteinPer100g: proteinPer100g,
                emoji: "🏷️", // Barcode icon to show it was scanned
                defaultPortionGrams: barcodeData.quantity
            )
            
            // Add protein entry from barcode result  
            let entry = dataManager.addProteinEntry(
                quantity: barcodeData.quantity,
                proteinGrams: barcodeData.protein,
                foodItem: foodItem
            )
            lastAddedEntry = entry
            showUndo()
            
            // Check for streak and achievements
            checkStreakAndAchievements()
            
            refreshCurrentData()
            loadDataForDate(selectedDate)
            
        case .failure(let error):
            print("Barcode error: \(error)")
            // Could show error alert here
        }
    }
    
    private func showUndo() {
        withAnimation { showUndoBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            withAnimation { showUndoBanner = false }
        }
    }
    
    private func loadQuickFoodItems() {
        // Initialize default foods if needed
        dataManager.initializeDefaultQuickFoods()
        
        // Load template foods from database 
        let templateFoods = dataManager.getTemplateFoodItems()
        
        // Load custom items from data manager
        let customItems = dataManager.getCustomFoodItems(limit: 3)
        
        // Combine both
        quickFoodItems = Array(templateFoods.prefix(6)) + Array(customItems.prefix(3))
        
        // Ensure we have at least some quick foods
        if quickFoodItems.isEmpty {
            quickFoodItems = FoodItem.defaultQuickFoods
        }
    }
    
    private func handleQuickFoodAdd(food: FoodItem, proteinDelta: Double) {
        if proteinDelta > 0 {
            // Adding protein
            let portions = proteinDelta / food.proteinPerPortion
            let entry = dataManager.addProteinFromQuickFood(food, portions: portions)
            lastAddedEntry = entry
            showUndo()
        } else {
            // Removing protein - find and delete last entry of this food
            let todaysEntries = dataManager.getTodaysEntries()
            
            if let lastEntryOfFood = todaysEntries.first(where: { entry in
                entry.foodItem?.id == food.id
            }) {
                dataManager.deleteEntry(lastEntryOfFood)
            }
        }
        
        refreshCurrentData()
        loadDataForDate(selectedDate)
    }
}

#Preview {
    NewHomeView()
        .environmentObject(DataManager.shared)
}