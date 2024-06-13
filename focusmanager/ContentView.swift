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
    @State private var message: String = "Hello, World!"
    @State private var selectedFileURL: URL? = nil
    
    var body: some View {
        VStack {
            Text(message)
                .padding()
                .frame(minWidth: 300, maxWidth: .infinity, minHeight: 150, maxHeight: .infinity)
            
            Button("Add Element") {
                print("Array starts like:", UserDefaults.standard.stringArray(forKey: "domains") ?? [])
                var stringArray = UserDefaults.standard.stringArray(forKey: "domains") ?? []
                
                stringArray.append("test")
                
                // Save array to UserDefaults
                UserDefaults.standard.set(stringArray, forKey: "domains")
                
                print("Array now looks like:", UserDefaults.standard.stringArray(forKey: "domains") ?? [])
//                writeToFile()
                
            }
            .padding()
            Button("Clear Defaults"){
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
            }.padding()
        }
    }
}


func writeToHostsFile() {
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


// Utility class for managing JSON operations
class HostManager {
    static let shared = HostManager()
    private let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Hosts.json")
    
    // Function to write Host objects to JSON file
    func saveHost(_ host: Host) {
        var hosts = loadHosts()
        hosts.append(host)
        saveHosts(hosts)
    }
    
    // Function to read all Host objects from JSON file
    func loadHosts() -> [Host] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        let decoder = JSONDecoder()
        do {
            let hosts = try decoder.decode([Host].self, from: data)
            return hosts
        } catch {
            print("Error decoding hosts: \(error.localizedDescription)")
            return []
        }
    }
    
    // Function to save updated array of Host objects to JSON file
    private func saveHosts(_ hosts: [Host]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(hosts)
            try data.write(to: fileURL)
        } catch {
            print("Error encoding hosts: \(error.localizedDescription)")
        }
    }
    
    // Function to delete a Host object from JSON file
    func deleteHost(at index: Int) {
        var hosts = loadHosts()
        hosts.remove(at: index)
        saveHosts(hosts)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

