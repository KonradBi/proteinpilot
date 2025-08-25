import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showSettings = false
    
    private var user: User? {
        dataManager.getCurrentUser()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.09),
                        Color(red: 0.12, green: 0.10, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        statsSection
                        settingsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image Placeholder
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
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.black)
                )
                .shadow(color: Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3), radius: 16, x: 0, y: 8)
            
            VStack(spacing: 8) {
                Text("Protein Pilot")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                if let user = user {
                    Text("Ziel: \(Int(user.proteinDailyTarget))g täglich")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiken")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard("🔥", "Streak", "7 Tage", Color.orange)
                statCard("📈", "Durchschnitt", "85g/Tag", Color.green)
                statCard("🏆", "Ziele erreicht", "21 von 30", Color.blue)
                statCard("⚡️", "Quick Adds", "156 total", Color.purple)
            }
        }
    }
    
    private func statCard(_ emoji: String, _ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.title)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Einstellungen")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                settingRow("person.circle", "Profil bearbeiten", "Ziele und Präferenzen") {}
                settingRow("bell", "Benachrichtigungen", "Erinnerungen verwalten") {}
                settingRow("chart.bar", "Export", "Daten exportieren") {}
                settingRow("questionmark.circle", "Hilfe", "FAQ und Support") {}
                settingRow("gear", "App-Einstellungen", "Themes und mehr") {}
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    private func settingRow(_ icon: String, _ title: String, _ subtitle: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(.title3, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .environmentObject(DataManager.shared)
}