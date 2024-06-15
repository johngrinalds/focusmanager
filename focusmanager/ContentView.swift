//
//  ContentView.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//
// Hardlink the hosts file with: sudo ln -f /Users/johngrinalds/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts /etc/hosts
// osascript -e 'quit app "Chrome"'

import SwiftUI
import Foundation

class SharedState: ObservableObject {
    @Published var domains: [String] = UserDefaults.standard.stringArray(forKey: "domains") ?? []
}

struct ContentView: View {
    @State private var userInput: String = ""
    @EnvironmentObject var sharedState: SharedState

    
    var body: some View {
        VStack {
            Text("Blocked Domains")
                .padding()
            
            List(sharedState.domains, id: \.self) { domain in
                            Text(domain)
                        }
            .padding()
            
            TextField("www.example.com", text: $userInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
            
            Button("Add Domain") {
                addDomain()
            }.padding()
            
            Button("Clear Domains"){
                clearDomains()
            }.padding()
            
            Button("Print Domains"){
                printDomains()
            }.padding()
        }
    }
    
    func addDomain(){
        if userInput != "" && !sharedState.domains.contains(userInput){
            sharedState.domains.append(userInput)
            sharedState.domains.sort()
            UserDefaults.standard.set(sharedState.domains, forKey: "domains")
        }
        userInput = ""
        writeToHostsFile()
    }
    
    func clearDomains(){
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        sharedState.domains = getDomains()
        writeToHostsFile()
    }
}

func getDomains() -> [String]{
    return UserDefaults.standard.stringArray(forKey: "domains") ?? []
}

func printDomains(){
    let temp = UserDefaults.standard.stringArray(forKey: "domains") ?? []
    for item in temp {
        print(item)
    }
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
            try text.write(to: fileURL, atomically: false, encoding: .utf8) // Note that atomic needs to be false, otherwise it will copy a new file, breaking the hard link
//            print("File created at: \(fileURL.path)")
        } catch {
            print("Error writing to file: \(error)")
        }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        flushDNSCache()
    }
    
}

func flushDNSCache() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["dscacheutil", "-flushcache"]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                print("DNS cache flushed successfully.")
            } else {
                print("Failed to flush DNS cache.")
            }
        } catch {
            print("Error running the process: \(error)")
        }
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

