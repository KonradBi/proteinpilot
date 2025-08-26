import SwiftUI

struct TodayPlanList: View {
    let plannedMeals: [PlannedMeal]
    let aggregatedEntries: [AggregatedEntry]
    let onPlannedMealComplete: (PlannedMeal) -> Void
    let onAggregatedEntryEdit: (AggregatedEntry) -> Void
    let onAggregatedEntryDelete: (AggregatedEntry) -> Void
    
    private var hasPlannedMeals: Bool {
        !plannedMeals.isEmpty
    }
    
    private var hasEatenItems: Bool {
        !aggregatedEntries.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Planned Meals Section
            if hasPlannedMeals {
                plannedMealsSection
            }
            
            // Eaten Items Section  
            if hasEatenItems {
                eatenItemsSection
            }
            
            // Empty state if no content
            if !hasPlannedMeals && !hasEatenItems {
                emptyState
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var plannedMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            plannedSectionHeader
            
            // Planned Meals List
            LazyVStack(spacing: 8) {
                ForEach(plannedMeals, id: \.id) { meal in
                    PlannedMealRow(
                        meal: meal,
                        onComplete: { onPlannedMealComplete(meal) }
                    )
                }
            }
        }
    }
    
    private var eatenItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            eatenSectionHeader
            
            // Eaten Items List
            LazyVStack(spacing: 8) {
                ForEach(aggregatedEntries, id: \.id) { entry in
                    AggregatedEntryRow(
                        entry: entry,
                        onEdit: { onAggregatedEntryEdit(entry) },
                        onDelete: { onAggregatedEntryDelete(entry) }
                    )
                }
            }
        }
    }
    
    private var plannedSectionHeader: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8), // Warm orange
                                Color(red: 0.9, green: 0.4, blue: 0.1).opacity(0.4), // Deep orange
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 24, height: 24)
                    .blur(radius: 6)
                
                Image(systemName: "calendar.badge.plus")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.7, blue: 0.2), // Warm orange
                                Color(red: 0.9, green: 0.5, blue: 0.1)  // Deep orange
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.system(.subheadline, weight: .bold))
            }
            
            Text("Geplant für heute")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(plannedMeals.count)")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                )
        }
    }
    
    private var eatenSectionHeader: some View {
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
                            endRadius: 12
                        )
                    )
                    .frame(width: 24, height: 24)
                    .blur(radius: 6)
                
                Image(systemName: "checkmark.circle.fill")
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
            }
            
            Text("Bereits gegessen")
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(aggregatedEntries.count)")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                )
        }
    }
    
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Noch nichts für heute")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Füge Empfehlungen hinzu oder trage gegessene Mahlzeiten ein")
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct PlannedMealRow: View {
    let meal: PlannedMeal
    let onComplete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var showingActions = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Text(meal.icon)
                .font(.system(.title2))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.2))
                        .overlay(
                            Circle()
                                .strokeBorder(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.4), lineWidth: 1)
                        )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    // Source badge
                    Text("EMPFEHLUNG")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.4), lineWidth: 0.5)
                                )
                        )
                    
                    // Protein amount
                    HStack(spacing: 2) {
                        Text("💪")
                            .font(.system(.caption2))
                        Text("\(Int(meal.expectedProtein))g")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                    
                    Spacer()
                }
            }
            
            // Complete Button
            Button(action: onComplete) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Hinzufügen")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                }
                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct AggregatedEntryRow: View {
    let entry: AggregatedEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var showingActions = false
    
    var body: some View {
        ZStack {
            // Background actions
            if showingActions {
                actionsBackground
            }
            
            // Main content
            itemContent
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 { // Only left swipe
                                dragOffset = value.translation
                                showingActions = abs(value.translation.width) > 50
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if abs(value.translation.width) > 100 {
                                    // Trigger delete action
                                    onDelete()
                                }
                                dragOffset = .zero
                                showingActions = false
                            }
                        }
                )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var itemContent: some View {
        HStack(spacing: 14) {
            // Icon
            Text(entry.icon)
                .font(.system(.title2))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2))
                        .overlay(
                            Circle()
                                .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), lineWidth: 1)
                        )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.displayText)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    // Type badge
                    Text("GEGESSEN")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), lineWidth: 0.5)
                                )
                        )
                    
                    // Protein amount
                    HStack(spacing: 2) {
                        Text("💪")
                            .font(.system(.caption2))
                        Text(entry.proteinText)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                    
                    Spacer()
                }
            }
            
            // Edit Button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
    
    
    
    
    
    private var actionsBackground: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 16) {
                // Edit action
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(red: 1.0, green: 0.6, blue: 0.2)))
                }
                
                // Delete action
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.red))
                }
            }
            .padding(.trailing, 16)
        }
    }
    
    
}


#Preview {
    ZStack {
        Color.black
        
        TodayPlanList(
            plannedMeals: [],
            aggregatedEntries: [],
            onPlannedMealComplete: { _ in print("Complete planned meal") },
            onAggregatedEntryEdit: { _ in print("Edit aggregated entry") },
            onAggregatedEntryDelete: { _ in print("Delete aggregated entry") }
        )
    }
}