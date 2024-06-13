//
//  ContentView.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//

import SwiftUI
import Foundation

// Define the Host struct conforming to Codable
struct Host: Codable {
    var domain: String
}

struct ContentView: View {
    @State private var userInput: String = ""
    @State private var message: String = "Hello, World!"
    @State private var domains: [String] = getDomains()

    
    var body: some View {
        VStack {
            Text(message)
                .padding()
            
            List(domains, id: \.self) { domain in
                            Text(domain)
                        }
            
            TextField("www.example.com", text: $userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
            
            Button("Add Domain") {
                addDomain()
            }.padding()
            
            Button("Clear Defaults"){
                clearDomains()
            }.padding()
        }
    }
    
    func addDomain(){
        if userInput != "" && !domains.contains(userInput){
            domains.append(userInput)
            domains.sort()
            UserDefaults.standard.set(domains, forKey: "domains")
        }
        userInput = ""
        writeToHostsFile()
    }
    
    func clearDomains(){
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        domains = getDomains()
        writeToHostsFile()
    }
}

func getDomains() -> [String]{
    return UserDefaults.standard.stringArray(forKey: "domains") ?? []
}

func writeToHostsFile() {
    // Text to write to the file
    var joinedDomains = ""
    if !getDomains().isEmpty{
        joinedDomains = "127.0.0.1" + " " + getDomains().joined(separator: "\n127.0.0.1 ")
    }
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
    \(joinedDomains)


    # Added by Docker Desktop
    # To allow the same kube context to work on the host and the container:
    127.0.0.1 kubernetes.docker.internal
    # End of section
    """
    
    let fileName = "focusmanager-hosts" // Name of the file
    
    // Find the document directory
    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        
        // Append the file name to the directory
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            // Write to the file
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
//            print("File created at: \(fileURL.path)")
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

