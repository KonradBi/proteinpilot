import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var searchText = ""
    @State private var selectedDateRange = 0
    
    private let dateRangeOptions = ["Heute", "Diese Woche", "Diesen Monat", "Alles"]
    
    var filteredEntries: [ProteinEntry] {
        let allEntries = dataManager.getRecentEntries(limit: 100)
        
        var dateFiltered = allEntries
        
        switch selectedDateRange {
        case 0: // Heute
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
            dateFiltered = allEntries.filter { $0.date >= today && $0.date < tomorrow }
            
        case 1: // Diese Woche
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            dateFiltered = allEntries.filter { $0.date >= weekAgo }
            
        case 2: // Diesen Monat
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            dateFiltered = allEntries.filter { $0.date >= monthAgo }
            
        default: // Alles
            dateFiltered = allEntries
        }
        
        if searchText.isEmpty {
            return dateFiltered
        } else {
            return dateFiltered.filter { entry in
                entry.displayName.localizedCaseInsensitiveContains(searchText) ||
                (entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    TextField("Suche...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Zeitraum", selection: $selectedDateRange) {
                        ForEach(0..<dateRangeOptions.count, id: \.self) { index in
                            Text(dateRangeOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                
                // Entries List
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(groupedEntries, id: \.key) { group in
                            Section(header: Text(group.key)) {
                                ForEach(group.value, id: \.id) { entry in
                                    EntryRowView(entry: entry) {
                                        dataManager.addProteinEntry(
                                            quantity: entry.quantity,
                                            proteinGrams: entry.proteinGrams,
                                            foodItem: entry.foodItem,
                                            mealType: entry.mealType
                                        )
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let entry = group.value[index]
                                        dataManager.deleteEntry(entry)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Verlauf")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Noch keine Einträge")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Füge deine ersten Protein-Einträge hinzu, um sie hier zu sehen.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var groupedEntries: [(key: String, value: [ProteinEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "de_DE")
            return formatter.string(from: entry.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
}

struct EntryRowView: View {
    let entry: ProteinEntry
    let onDuplicate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let mealType = entry.mealType {
                        Text("• \(mealType)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.proteinGrams))g")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Button(action: onDuplicate) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environmentObject(DataManager.shared)
}