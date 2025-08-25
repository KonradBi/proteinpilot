//
//  ProteinPilotApp.swift
//  ProteinPilot
//
//  Created by Konrad on 23.08.25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ProteinPilotApp: App {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(notificationService)
                .modelContainer(dataManager.context.container)
                .onAppear {
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        Task {
            await notificationService.setupNotificationActions()
            
            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        }
    }
}

nonisolated class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NotificationService.shared.handleNotificationAction(response.actionIdentifier) {
                completionHandler()
            }
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
