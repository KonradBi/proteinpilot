import SwiftUI

// MARK: - Developer Tool: Pre-Launch Seeding
// Only shown in DEBUG builds for manual recipe collection
struct PreLaunchSeedingView: View {
    @State private var seedingStatus = SeedingStatus(
        currentCount: 0, 
        targetCount: APIConfig.targetRecipeCount, 
        progress: 0, 
        isComplete: false, 
        apiRecipes: 0, 
        localRecipes: 0
    )
    @State private var isSeeding = false
    @State private var seedingLog: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🎯 Pre-Launch Seeding")
                            .font(.headline)
                        Spacer()
                        Text(seedingStatus.progressPercentage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: seedingStatus.progress)
                        .tint(.blue)
                    
                    Text(seedingStatus.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Recipe breakdown
                    HStack {
                        VStack(alignment: .leading) {
                            Text("📦 Total")
                            Text("\(seedingStatus.currentCount)")
                                .font(.title2)
                                .bold()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("🌐 API")
                            Text("\(seedingStatus.apiRecipes)")
                                .font(.title2)
                                .bold()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("🏠 Local")
                            Text("\(seedingStatus.localRecipes)")
                                .font(.title2)
                                .bold()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !seedingStatus.isComplete {
                        Button(action: startSeeding) {
                            HStack {
                                if isSeeding {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "cloud.fill")
                                }
                                Text(isSeeding ? "Seeding..." : "Run Daily Seeding")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSeeding || !APIConfig.isAPIKeyValid)
                        
                        if !APIConfig.isAPIKeyValid {
                            Text("⚠️ Configure API key in APIConfig.swift first")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Button(action: exportBundle) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Production Bundle")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    Button(action: refreshStatus) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Status")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Seeding Log
                if !seedingLog.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📋 Seeding Log")
                                .font(.headline)
                            
                            ForEach(seedingLog, id: \.self) { logEntry in
                                Text(logEntry)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Recipe Seeding")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshStatus()
        }
    }
    
    // MARK: - Actions
    
    private func startSeeding() {
        isSeeding = true
        seedingLog.append("🚀 Starting pre-launch seeding...")
        
        Task {
            await DataManager.shared.runPreLaunchSeeding()
            
            await MainActor.run {
                isSeeding = false
                refreshStatus()
                seedingLog.append("✅ Seeding session complete")
            }
        }
    }
    
    private func refreshStatus() {
        seedingStatus = DataManager.shared.getSeedingProgress()
    }
    
    private func exportBundle() {
        Task {
            let summary = await PreLaunchSeedingService.shared.exportRecipeBundleForProduction()
            await MainActor.run {
                seedingLog.append("📦 Bundle exported:")
                seedingLog.append(summary)
            }
        }
    }
}

// MARK: - Developer Menu Extension (removed for now to avoid compilation issues)

#Preview {
    PreLaunchSeedingView()
}