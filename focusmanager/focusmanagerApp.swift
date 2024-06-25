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
    @StateObject private var hostsFileManager = HostsFileManager()
    @StateObject private var statusBarController = StatusBarController()
    @State private var showWelcomeAlert = false
    
    let hostsAlertText = """
    The managed hosts file does not exist yet. Before proceeding, visit the following link to complete the setup then quit and restart the program:
    
    https://github.com/johngrinalds/focusmanager/tree/main?tab=readme-ov-file#installation
    """
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
                .environmentObject(hostsFileManager)
                .environmentObject(statusBarController)
                .onAppear {
                    statusBarController.setup()
                    if !hostsFileManager.fileExists() {
                        showWelcomeAlert = true
                    } else {
                        hostsFileManager.getCurrentFileContents()
                        if !hostsFileManager.managedSectionExists() {
                            hostsFileManager.addManagedSection()
                        }
                    }
                    }
                    .alert(isPresented: $showWelcomeAlert) {
                        Alert(title: Text("Welcome!"),
                              message: Text(hostsAlertText),
                              dismissButton: .destructive(Text("Quit")) {
                            NSApplication.shared.terminate(nil)
                        })
                    }
        }
    }
}
