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
    @State private var selectedFileURL: URL? = nil
    
    var body: some View {
        VStack {
            Text(message)
                .padding()
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity)
            
            Button("Click Me") {
                writeToFile()
                
            }
            .padding()
        }
    }
}


func writeToFile() {
    // Text to write to the file
    let text = """
    ##
    # Host Database
    #
    # localhost is used to configure the loopback interface
    # when the system is booting.  Do not change this entry.
    ##
    127.0.0.1    localhost
    255.255.255.255    broadcasthost
    ::1             localhost

    # https://www.autodidacts.io/coldturkey-selfcontrol-freedom-leechblock-alternative-in-bash/
    # This is copied to /etc/hosts when the script in the .zshrc file is run
    127.0.0.1 www.wsj.com
    #127.0.0.1 www.instagram.com
    #127.0.0.1 www.youtube.com
    #127.0.0.1 hckrnews.com
    #127.0.0.1 news.ycombinator.com
    #127.0.0.1 www.linkedin.com


    # Added by Docker Desktop
    # To allow the same kube context to work on the host and the container:
    127.0.0.1 kubernetes.docker.internal
    # End of section
    """
    let fileName = "output.txt" // Name of the file
    
    // Find the document directory
    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        
        // Append the file name to the directory
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            // Write to the file
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File created at: \(fileURL.path)")
        } catch {
            print("Error writing to file: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

