import SwiftUI

struct WeekStripCalendar: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onLongPress: ((Date) -> Void)?
    
    @State private var dragOffset: CGFloat = 0
    @State private var currentWeekOffset: Int = 0
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(selectedDate: Binding<Date>, 
         onDateSelected: @escaping (Date) -> Void,
         onLongPress: ((Date) -> Void)? = nil) {
        self._selectedDate = selectedDate
        self.onDateSelected = onDateSelected
        self.onLongPress = onLongPress
        
        dateFormatter.locale = Locale(identifier: "de_DE")
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Month/Year indicator
            monthHeader
            
            // Week strip with 7 days
            weekStrip
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var monthHeader: some View {
        HStack {
            Text(monthYearText)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { moveWeek(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Button(action: { moveWeek(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
    
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { date in
                dayView(for: date)
                    .frame(maxWidth: .infinity)
            }
        }
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if abs(value.translation.width) > threshold {
                        let direction = value.translation.width > 0 ? -1 : 1
                        moveWeek(direction)
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
        )
    }
    
    private func dayView(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isWeekend = calendar.isDateInWeekend(date)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
                onDateSelected(date)
            }
        }) {
            VStack(spacing: 6) {
                // Day of week (Mo, Di, ...)
                Text(dayOfWeekText(for: date))
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(dayOfWeekColor(isSelected: isSelected, isWeekend: isWeekend))
                
                // Day number with background
                ZStack {
                    if isSelected {
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
                            .frame(width: 34, height: 34)
                            .shadow(
                                color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.4),
                                radius: 6,
                                x: 0,
                                y: 3
                            )
                    } else if isToday {
                        Circle()
                            .stroke(
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                                lineWidth: 2
                            )
                            .frame(width: 34, height: 34)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 34, height: 34)
                    }
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(.subheadline, design: .rounded, weight: isSelected ? .bold : .medium))
                        .foregroundColor(dayNumberColor(isSelected: isSelected, isToday: isToday))
                }
                
                // Protein progress indicator (optional)
                proteinIndicator(for: date, isSelected: isSelected)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            onLongPress?(date)
        }
    }
    
    private func proteinIndicator(for date: Date, isSelected: Bool) -> some View {
        // This would show protein progress for the day
        // For now, showing a simple indicator
        Rectangle()
            .fill(
                isSelected ? 
                Color.white.opacity(0.3) : 
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4)
            )
            .frame(width: 20, height: 2)
            .cornerRadius(1)
    }
    
    // MARK: - Computed Properties
    
    private var weekDays: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: adjustedReferenceDate)?.start ?? Date()
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var adjustedReferenceDate: Date {
        let today = Date()
        return calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: today) ?? today
    }
    
    private var monthYearText: String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: adjustedReferenceDate)
    }
    
    // MARK: - Helper Methods
    
    private func dayOfWeekText(for date: Date) -> String {
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: date).uppercased()
    }
    
    private func dayOfWeekColor(isSelected: Bool, isWeekend: Bool) -> Color {
        if isSelected {
            return .white
        } else if isWeekend {
            return .white.opacity(0.5)
        } else {
            return .white.opacity(0.7)
        }
    }
    
    private func dayNumberColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected {
            return .black
        } else if isToday {
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        } else {
            return .white.opacity(0.85)
        }
    }
    
    private func moveWeek(_ direction: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentWeekOffset += direction
        }
        
        // Auto-select first day of new week if needed
        let newWeekStart = weekDays.first ?? Date()
        if !weekDays.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) {
            selectedDate = newWeekStart
            onDateSelected(newWeekStart)
        }
    }
}

#Preview {
    @Previewable @State var selectedDate = Date()
    
    return ZStack {
        Color.black
        
        WeekStripCalendar(
            selectedDate: $selectedDate,
            onDateSelected: { date in
                print("Selected: \(date)")
            },
            onLongPress: { date in
                print("Long pressed: \(date)")
            }
        )
    }
}