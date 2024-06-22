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
    @State private var showAlert = false
    
    let hostsAlertText = """
    The managed hosts file does not exist yet. Before proceeding, run the following commands:
    
    sudo cp /etc/hosts /etc/hosts.backup
    
    sudo ln -f /etc/hosts /Users/<USER>/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts
    
    sudo chown <USER>:staff /Users/<USER>/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts
    """
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedState)
                .onAppear {
                        if !managedHostFileExists() {
                            showAlert = true
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Welcome!"),
                              message: Text(hostsAlertText),
                              dismissButton: .default(Text("OK")))
                    }
        }
    }
}


func managedHostFileExists() -> Bool{
    let fileName = "focusmanager-hosts" // Name of the file
    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        // Check if the file exists at the specified URL
        let filePath = fileURL.path
        if FileManager.default.fileExists(atPath: filePath) {
            print("File exists at path: \(filePath)")
            return true
        } else {
            print("File does not exist at path: \(filePath)")
            return false
        }
    }
    return false
}
