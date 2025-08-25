import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Discover")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profil")
                }
        }
        .accentColor(Color(red: 1.0, green: 0.65, blue: 0.0))
    }
}

#Preview {
    MainTabView()
        .environmentObject(DataManager.shared)
}