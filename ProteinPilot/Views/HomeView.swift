import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var calendarService = CalendarService.shared
    
    @State private var todaysProtein: Double = 0
    @State private var proteinTarget: Double = 100
    @State private var showingAddEntry = false
    @State private var quickAddAmount = ""
    @State private var lastAddedEntry: ProteinEntry?
    @State private var showUndoBanner = false
    @State private var addInitialTab: Int = 0
    @State private var isRecordingVoice = false
    @State private var customItems: [FoodItem] = []
    @State private var quickSources: [QuickSource] = []
    @State private var quickFoodItems: [FoodItem] = []
    @State private var primaryAction: PrimaryRingAction = .voice
    @State private var showingCamera = false
    @State private var showingBarcodeScanner = false
    
    var progressPercentage: Double {
        guard proteinTarget > 0 else { return 0 }
        return min(todaysProtein / proteinTarget, 1.0)
    }
    
    private var titleHeader: some View {
        HStack(alignment: .center) {
            Text("ProteinPilot")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),   // Bright yellow
                            Color(red: 1.0, green: 0.65, blue: 0.0),   // Orange-yellow
                            Color(red: 0.9, green: 0.2, blue: 0.1)     // Red-orange
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            Spacer()
            if calendarService.hasCalendarAccess {
                scheduleIndicator
            }
        }
        .padding(.top, 6)
    }
    
    var remainingProtein: Double {
        max(0, proteinTarget - todaysProtein)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    titleHeader
                    scheduleStatusHeader
                    
                    proteinRingView
                    
                    
                    
                    recentEntriesSection
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .toolbar(.hidden, for: .navigationBar)
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.05, blue: 0.05),  // Deep red
                        Color(red: 0.15, green: 0.08, blue: 0.02), // Red-brown
                        Color(red: 0.18, green: 0.12, blue: 0.03)  // Warm brown
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                updateData()
                requestCalendarAccess()
                loadCustomItems()
                loadQuickSources()
                loadQuickFoodItems()
                setupSmartDefaults()
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(initialTab: addInitialTab)
                    .onDisappear {
                        updateData()
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
        }
        .overlay(alignment: .bottom) {
            if showUndoBanner, let entry = lastAddedEntry {
                undoBanner(entry: entry)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var scheduleStatusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Heute")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private var scheduleIndicator: some View {
        HStack(spacing: 8) {
            let analysis = calendarService.analyzeScheduleForMealTiming()
            
            Circle()
                .fill(stressLevelColor(analysis.stressLevel))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(analysis.timeOfDay.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(analysis.availableTime) min frei")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func stressLevelColor(_ level: StressLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .orange  
        case .high: return .red
        }
    }
    
    
    
    
    private func urgencyColor(_ urgency: MealUrgency) -> Color {
        switch urgency {
        case .critical: return .red
        case .urgent: return .orange
        case .normal: return .blue
        }
    }
    
    private var proteinRingView: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 16
                    )
                    .frame(width: 220, height: 220)
                
                // Progress Ring - Premium Whey Style
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        LinearGradient(
                            colors: progressPercentage >= 1.0 
                                ? [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),   // Bright yellow
                                    Color(red: 1.0, green: 0.75, blue: 0.0),   // Golden yellow
                                    Color(red: 0.9, green: 0.6, blue: 0.1)     // Orange-gold
                                ]
                                : [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),   // Bright yellow
                                    Color(red: 1.0, green: 0.65, blue: 0.0),   // Orange-yellow
                                    Color(red: 0.9, green: 0.2, blue: 0.1)     // Red-orange
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.4), radius: 12, x: 0, y: 0)
                    .animation(.interpolatingSpring(stiffness: 150, damping: 20), value: progressPercentage)
                
                // Center Content with Progress Integration
                VStack(spacing: 6) {
                    Text("\(Int(todaysProtein))")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),   // Bright yellow
                                    Color(red: 1.0, green: 0.65, blue: 0.0),   // Orange-yellow
                                    Color(red: 0.9, green: 0.2, blue: 0.1)     // Red-orange
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // Progress and Target in one line
                    HStack(spacing: 6) {
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), lineWidth: 1)
                                    )
                            )
                        
                        Text("von \(Int(proteinTarget))g")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if remainingProtein > 0 {
                        primaryActionButton
                            .padding(.top, 6)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Text("Ziel erreicht!")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), lineWidth: 1)
                                )
                        )
                        .padding(.top, 8)
                    }
                }
            }
            
            // Action Bar (Voice, Camera, Manual, Barcode)
            actionBar
            
            // Quick Food Chips (Tap-to-Increment)
            if !quickFoodItems.isEmpty {
                quickFoodChipsSection
            }
            
            // Legacy Quick Sources (for comparison)
            if !quickSources.isEmpty {
                primaryQuickSources
            }
        }
    }
    
    

    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.0))
                Text("Schnell hinzufügen")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                TextField("z.B. 25g", text: $quickAddAmount)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .font(.system(.body, design: .rounded))
                
                Button(action: {
                    if let amount = Double(quickAddAmount), amount > 0 {
                        let entry = dataManager.addProteinEntry(
                            quantity: amount,
                            proteinGrams: amount
                        )
                        lastAddedEntry = entry
                        showUndo()
                        quickAddAmount = ""
                        updateData()
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(quickAddAmount.isEmpty ? .gray : .blue)
                }
                .disabled(quickAddAmount.isEmpty)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                quickAddButton(amount: 10)
                quickAddButton(amount: 20)
                quickAddButton(amount: 30)
                quickAddButton(amount: 50)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.black.opacity(0.06))
                )
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
    
    private func quickAddButton(amount: Double) -> some View {
        Button(action: {
            let entry = dataManager.addProteinEntry(
                quantity: amount,
                proteinGrams: amount
            )
            lastAddedEntry = entry
            showUndo()
            updateData()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Text("\(Int(amount))")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Text("g")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }

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
                    updateData()
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

    private func showUndo() {
        withAnimation { showUndoBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { showUndoBanner = false }
        }
    }
    
    private var todaysSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Heute empfohlen")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Alle anzeigen") {
                    
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    suggestionCard(name: "Griechischer Joghurt", protein: 20, prepTime: 2)
                    suggestionCard(name: "Protein Shake", protein: 25, prepTime: 3)
                    suggestionCard(name: "Hüttenkäse", protein: 18, prepTime: 1)
                }
                .padding(.horizontal, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.black.opacity(0.06))
                )
        )
    }
    
    private func suggestionCard(name: String, protein: Double, prepTime: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            HStack {
                Text("\(Int(protein))g Protein")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(prepTime)min")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button("Hinzufügen") {
                dataManager.addProteinEntry(
                    quantity: 100,
                    proteinGrams: protein
                )
                updateData()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(width: 160)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with glow effect
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.8),
                                    Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 15
                            )
                        )
                        .frame(width: 30, height: 30)
                        .blur(radius: 8)
                    
                    Image(systemName: "clock.arrow.circlepath")
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
                        .font(.system(.title3, weight: .semibold))
                        .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.5), radius: 4, x: 0, y: 2)
                }
                
                Text("Letzte Einträge")
                    .font(.system(.title2, design: .rounded, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                Button("Alle anzeigen") {
                    // TODO: Navigate to history view
                }
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            let recentEntries = dataManager.getRecentEntries(limit: 4)
            
            if recentEntries.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Bereit für deine ersten Einträge")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Individual Cards statt Table
                VStack(spacing: 8) {
                    ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                        recentEntryCard(entry)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    private func recentEntryRow(_ entry: ProteinEntry, isLast: Bool) -> some View {
        VStack(spacing: 12) {
            // Modern Card Design - wie Instagram Story
            HStack(spacing: 0) {
                // Left: Food Icon + Info
                HStack(spacing: 12) {
                    // Food Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.85, blue: 0.0),
                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        if let foodItem = entry.foodItem, let emoji = foodItem.emoji, !emoji.isEmpty {
                            Text(emoji)
                                .font(.system(size: 20, weight: .medium))
                        } else {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black.opacity(0.8))
                        }
                    }
                    
                    // Food Name + Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(betterDisplayName(for: entry))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(entry.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Right: Protein Badge + Actions  
                HStack(spacing: 12) {
                    // Protein Amount - Prominent
                    VStack(spacing: 2) {
                        Text("\(Int(entry.proteinGrams))")
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        Text("PROTEIN")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    
                    // Action Buttons - Vertical Stack
                    VStack(spacing: 8) {
                        Button(action: {
                            let newEntry = dataManager.addProteinEntry(
                                quantity: entry.quantity,
                                proteinGrams: entry.proteinGrams,
                                foodItem: entry.foodItem
                            )
                            lastAddedEntry = newEntry
                            showUndo()
                            updateData()
                            
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                deleteEntry(entry)
                            }
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Stylish Divider (nur wenn nicht letzter)
            if !isLast {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Modern Card Design
    private func recentEntryCard(_ entry: ProteinEntry) -> some View {
        HStack(spacing: 0) {
            // Left: Food Icon + Info
            HStack(spacing: 14) {
                // Food Icon - Bigger and More Prominent
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.0),
                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    if let foodItem = entry.foodItem, let emoji = foodItem.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 22, weight: .medium))
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
                
                // Food Name + Time
                VStack(alignment: .leading, spacing: 6) {
                    Text(betterDisplayName(for: entry))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(.caption2, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(entry.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Right: Modern Protein Display + Actions
            HStack(spacing: 16) {
                // Protein Display - Instagram-Style
                VStack(spacing: 4) {
                    Text("\(Int(entry.proteinGrams))g")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.9, blue: 0.0),
                                    Color(red: 1.0, green: 0.6, blue: 0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("PROTEIN")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)
                }
                
                // Action Buttons - Modern Style
                VStack(spacing: 12) {
                    Button(action: {
                        let newEntry = dataManager.addProteinEntry(
                            quantity: entry.quantity,
                            proteinGrams: entry.proteinGrams,
                            foodItem: entry.foodItem
                        )
                        lastAddedEntry = newEntry
                        showUndo()
                        updateData()
                        
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            deleteEntry(entry)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(0.04),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
    }
    
    private func deleteEntry(_ entry: ProteinEntry) {
        dataManager.deleteEntry(entry)
        updateData()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func requestCalendarAccess() {
        Task {
            await calendarService.requestCalendarAccess()
            if calendarService.hasCalendarAccess {
                calendarService.getUpcomingEvents()
                    }
        }
    }
    
    
    
    private func updateData() {
        todaysProtein = dataManager.getTodaysTotalProtein()
        if let user = dataManager.getCurrentUser() {
            proteinTarget = user.proteinDailyTarget
        }
        dataManager.updateTodaysBalance()
        loadQuickSources()
        loadQuickFoodItems()
    }

    private func loadCustomItems() {
        customItems = dataManager.getCustomFoodItems(limit: 8)
    }
    
    private func loadQuickSources() {
        var sources: [QuickSource] = []
        
        // Add recent entries as quick sources
        let recentEntries = dataManager.getRecentEntries(limit: 10)
        let groupedEntries = Dictionary(grouping: recentEntries) { entry in
            entry.foodItem?.name ?? "Protein"
        }
        
        for (name, entries) in groupedEntries {
            let mostRecent = entries.first!
            let avgProtein = entries.map(\.proteinGrams).reduce(0, +) / Double(entries.count)
            
            sources.append(QuickSource(
                name: name,
                proteinAmount: avgProtein,
                type: .recent,
                lastUsed: mostRecent.createdAt,
                usageCount: entries.count,
                foodItem: mostRecent.foodItem
            ))
        }
        
        // Add custom items as quick sources
        for item in customItems {
            sources.append(QuickSource(
                name: item.name,
                proteinAmount: item.proteinPer100g,
                type: .custom,
                lastUsed: item.updatedAt,
                usageCount: 1, // Could be tracked separately
                foodItem: item
            ))
        }
        
        // Sort by priority and take top 6
        quickSources = sources
            .sorted { $0.sortPriority > $1.sortPriority }
            .prefix(6)
            .map { $0 }
    }
    
    private func updateQuickSourceUsage(_ source: QuickSource) {
        // In a real app, this would update usage statistics
        // For now, we'll reload the sources which will naturally update based on recent entries
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadQuickSources()
        }
    }
    
    private func setupSmartDefaults() {
        // Check if user has a preferred action stored
        if let savedAction = UserDefaults.standard.object(forKey: "primaryRingAction") as? String,
           let action = PrimaryRingAction.allCases.first(where: { $0.title == savedAction }) {
            primaryAction = action
        } else {
            // Use smart default based on time of day
            primaryAction = PrimaryRingAction.smartDefault
        }
    }
    
    private func savePrimaryActionPreference() {
        UserDefaults.standard.set(primaryAction.title, forKey: "primaryRingAction")
    }
    
    private func loadQuickFoodItems() {
        // Initialize default foods if needed
        dataManager.initializeDefaultQuickFoods()
        
        // Load quick food items
        quickFoodItems = dataManager.getQuickFoodItems(limit: 6)
        
        // Debug: Print loaded items
        print("🔍 Loaded \(quickFoodItems.count) quick food items:")
        for item in quickFoodItems {
            print("  - \(item.emoji ?? "❓") \(item.name): \(item.proteinPerPortion)g protein")
        }
    }
    
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
        
        updateData()
    }
    
    private func betterDisplayName(for entry: ProteinEntry) -> String {
        if let foodItem = entry.foodItem {
            let emoji = foodItem.emoji ?? ""
            let emojiPrefix = emoji.isEmpty ? "" : "\(emoji) "
            
            // Show full product name for scanned items
            let fullName = foodItem.name
            
            // Calculate portions for better display
            let portions = entry.quantity / foodItem.defaultPortionGrams
            
            if portions == 1.0 {
                return "\(emojiPrefix)\(fullName)"
            } else if portions.truncatingRemainder(dividingBy: 1) == 0 {
                // Whole number of portions
                return "\(emojiPrefix)\(Int(portions))x \(fullName)"
            } else {
                // Fractional portions - show grams
                return "\(emojiPrefix)\(Int(entry.quantity))g \(fullName)"
            }
        }
        
        // Fallback for entries without food item - show more descriptive name
        if entry.proteinGrams >= 20 {
            return "🥛 Protein Shake \(Int(entry.proteinGrams))g"
        } else if entry.proteinGrams >= 10 {
            return "🧀 Protein Snack \(Int(entry.proteinGrams))g" 
        } else {
            return "⚡ Protein \(Int(entry.proteinGrams))g"
        }
    }

    private func toggleVoice() {
        isRecordingVoice.toggle()
        // TODO: Integrate Whisper streaming; for now simulate stop after short time
        if isRecordingVoice {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isRecordingVoice = false
            }
        }
    }

    private var primaryQuickSources: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Legacy Quick Sources")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
            
            // First row: Most used quick sources (3-4 items)
            HStack(spacing: 8) {
                ForEach(Array(quickSources.prefix(4)), id: \.id) { source in
                    quickSourceChip(source)
                }
                Spacer()
            }
            
            // Second row if more items (2-3 items + scan chip)
            if quickSources.count > 4 {
                HStack(spacing: 8) {
                    ForEach(Array(quickSources.dropFirst(4).prefix(2)), id: \.id) { source in
                        quickSourceChip(source)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    
    private func quickSourceChip(_ source: QuickSource) -> some View {
        Button(action: {
            let entry = dataManager.addProteinEntry(
                quantity: source.proteinAmount,
                proteinGrams: source.proteinAmount,
                foodItem: source.foodItem
            )
            lastAddedEntry = entry
            showUndo()
            updateData()
            updateQuickSourceUsage(source)
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            HStack(spacing: 6) {
                Text(source.displayName)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(Int(source.proteinAmount))g")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0),
                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var primaryActionButton: some View {
        Button(action: { executePrimaryAction() }) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                                Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 68, height: 68)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0),
                                Color(red: 1.0, green: 0.65, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.4), radius: 12, x: 0, y: 6)
                
                // Icon with better styling
                Image(systemName: primaryAction == .voice && isRecordingVoice ? "stop.circle.fill" : primaryAction.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .scaleEffect(primaryAction == .voice && isRecordingVoice ? 1.1 : 1.0)
            .animation(.interpolatingSpring(stiffness: 300, damping: 15), value: isRecordingVoice)
        }
        .buttonStyle(.plain)
    }
    
    private var actionBar: some View {
        HStack(spacing: 8) {
            ForEach(PrimaryRingAction.allCases, id: \.self) { action in
                actionBarButton(for: action)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func actionBarButton(for action: PrimaryRingAction) -> some View {
        let isActive = action == primaryAction
        
        return Button(action: { 
            switchToPrimaryAction(action)
        }) {
            ZStack {
                // Background with subtle glow
                Circle()
                    .fill(
                        isActive ? 
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0),
                                Color(red: 1.0, green: 0.65, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isActive ?
                                Color.white.opacity(0.3) :
                                Color.white.opacity(0.15),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isActive ? Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                // Icon
                Image(systemName: action.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? .black : .white.opacity(0.85))
                    .shadow(
                        color: isActive ? .white.opacity(0.2) : .clear,
                        radius: 1,
                        x: 0,
                        y: 1
                    )
            }
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.interpolatingSpring(stiffness: 400, damping: 20), value: isActive)
        }
        .buttonStyle(.plain)
    }
    
    private func executePrimaryAction() {
        switch primaryAction {
        case .voice:
            toggleVoice()
        case .camera:
            // Direct camera access
            showingCamera = true
        case .manual:
            // Manual input opens modal
            addInitialTab = 0
            showingAddEntry = true
        case .barcode:
            // Direct barcode scanner access
            showingBarcodeScanner = true
        }
    }
    
    private func switchToPrimaryAction(_ action: PrimaryRingAction) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            primaryAction = action
        }
        
        // Save user preference
        savePrimaryActionPreference()
        
        // Execute the action immediately after switching
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            executePrimaryAction()
        }
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
            updateData()
            
        case .failure(let error):
            print("Camera error: \(error)")
            // Could show error alert here
        }
    }
    
    private func handleBarcodeResult(_ result: BarcodeResult) {
        switch result {
        case .success(let foodData):
            // Create or find food item for scanned barcode
            let proteinPer100g = (foodData.protein / foodData.quantity) * 100
            let foodItem = dataManager.createCustomFoodItem(
                name: foodData.foodName ?? "Gescanntes Produkt",
                proteinPer100g: proteinPer100g,
                emoji: "🏷️", // Barcode icon to show it was scanned
                defaultPortionGrams: foodData.quantity
            )
            
            // Add protein entry from barcode result  
            let entry = dataManager.addProteinEntry(
                quantity: foodData.quantity,
                proteinGrams: foodData.protein,
                foodItem: foodItem
            )
            lastAddedEntry = entry
            showUndo()
            updateData()
            
        case .failure(let error):
            print("Barcode error: \(error)")
            // Could show error alert here
        }
    }
    
    private var customQuickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deine schnellen Quellen")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(customItems, id: \.id) { item in
                        Button(action: {
                            let grams = item.proteinPer100g
                            let entry = dataManager.addProteinEntry(quantity: 100, proteinGrams: grams, foodItem: item)
                            lastAddedEntry = entry
                            showUndo()
                            updateData()
                        }) {
                            HStack(spacing: 6) {
                                Text(item.name)
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text("\(Int(item.proteinPer100g))g")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(red: 1.0, green: 0.84, blue: 0.0)))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.25)))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager.shared)
}