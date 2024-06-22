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
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showAlert = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
                .onAppear {
                        if !hasLaunchedBefore {
                            showAlert = true
                            hasLaunchedBefore = true
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Welcome!"),
                              message: Text("This is the first time you've launched the app."),
                              dismissButton: .default(Text("OK")))
                    }
        }
    }
}
