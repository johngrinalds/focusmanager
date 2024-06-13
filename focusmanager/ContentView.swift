//
//  ContentView.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var message: String = "Hello, World!"
    
    var body: some View {
        VStack {
            Text(message)
                .padding()
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity)
            
            Button(action: {
                // Get the URL of the file within the App Group container
                
                let dialog = NSOpenPanel()
                        
                dialog.title                   = "Choose a file"
                dialog.showsResizeIndicator    = true
                dialog.showsHiddenFiles        = false
                dialog.allowsMultipleSelection = false
                dialog.canChooseDirectories    = false
                
                if dialog.runModal() == NSApplication.ModalResponse.OK {
                    if let fileURL = dialog.url {
                        do {
                            message = try String(contentsOfFile: fileURL.path, encoding: .utf8)
                            print("File contents are: \(message)")
                        } catch {
                            print("Error reading file: \(error)")
                        }
                    }
                } else {
                    message = "No file selected"
                }
                
                
            }) {
                Text("Click Me")
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

