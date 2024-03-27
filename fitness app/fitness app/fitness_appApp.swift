//
//  fitness_appApp.swift
//  fitness app
//
//  Created by Harris Kim on 2/23/24.
//

import SwiftUI
import Firebase

@main
struct fitness_appApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
