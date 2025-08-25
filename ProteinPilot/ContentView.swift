//
//  ContentView.swift
//  ProteinPilot
//
//  Created by Konrad on 23.08.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if dataManager.getCurrentUser() == nil {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
