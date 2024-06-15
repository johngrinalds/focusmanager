//
//  focusmanagerApp.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//

import SwiftUI

@main
struct focusmanagerApp: App {
    @StateObject private var sharedState = SharedState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
        }
    }
}
