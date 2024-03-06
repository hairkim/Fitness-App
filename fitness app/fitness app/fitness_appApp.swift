//
//  fitness_appApp.swift
//  fitness app
//
//  Created by Harris Kim on 2/23/24.
//

import SwiftUI

@main
struct fitness_appApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
