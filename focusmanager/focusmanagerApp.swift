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
    
    curl -s https://gist.githubusercontent.com/johngrinalds/e1eba94db0218256a766cf0e011b8904/raw/fabf9f9c5370624a01f0e3d3ebdac5284dfb9e68/setup.sh | bash -s <USER>
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
