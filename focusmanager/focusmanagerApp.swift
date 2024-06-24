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
    The managed hosts file does not exist yet. Before proceeding, run the following commands and then quit and restart the program:
    
    curl -s https://gist.githubusercontent.com/johngrinalds/e1eba94db0218256a766cf0e011b8904/raw/f94c4166fed25eff4a2e5e496152dbb8aab60151/setup.sh | bash -s <USER>
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
