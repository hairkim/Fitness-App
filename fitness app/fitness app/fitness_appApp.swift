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

@main
struct fitness_appApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userStore = UserStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userStore)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
