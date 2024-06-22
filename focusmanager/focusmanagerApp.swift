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
    @State private var showAlert = false
    
    let hostsAlertText = """
    The managed hosts file does not exist yet. Before proceeding, run the following commands and then quit and restart the program:
    
    sudo cp /etc/hosts /etc/hosts.backup
    
    sudo ln -f /etc/hosts /Users/<USER>/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts
    
    sudo chown <USER>:staff /Users/<USER>/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts
    """
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
                .environmentObject(hostFileManager)
                .onAppear {
                    if !hostFileManager.managedHostFileExists() {
                            showAlert = true
                    } else {
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
