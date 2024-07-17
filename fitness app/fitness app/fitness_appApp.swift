//
//  fitness_appApp.swift
//  fitness app
//
//  Created by Harris Kim on 2/23/24.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore
import UserNotifications

@main
struct fitness_appApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userStore = UserStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(userStore: userStore) // Pass the userStore here
                .environmentObject(userStore)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        setupNotification()
        return true
    }
    
    private func setupNotification() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Handle notifications in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    // Handle notifications when app is in background or terminated
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
