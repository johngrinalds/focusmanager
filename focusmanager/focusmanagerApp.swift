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
    @StateObject private var hostFileManager = HostFileManager()
    @StateObject private var statusBarController = StatusBarController()
    @State private var showAlert = false
    
    let hostsAlertText = """
    The managed hosts file does not exist yet. Before proceeding, visit the following link to complete the setup then quit and restart the program:
    
    https://github.com/johngrinalds/focusmanager/tree/main?tab=readme-ov-file#installation
    """
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
                .environmentObject(hostFileManager)
                .environmentObject(statusBarController)
                .onAppear {
                    statusBarController.setup()
                    if !hostFileManager.managedHostFileExists() {
                            showAlert = true
                    } else {
                        hostFileManager.getCurrentHostsFileContents()
                        if !hostFileManager.checkIfManagedBlock() {
                            hostFileManager.addManagedBlock()
                        }
                    }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Welcome!"),
                              message: Text(hostsAlertText),
                              dismissButton: .destructive(Text("Quit")) {
                            NSApplication.shared.terminate(nil)
                        })
                    }
        }
    }
}
