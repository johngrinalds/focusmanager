//
//  HostFileManager.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import Foundation

class HostFileManager: ObservableObject {
    private var hostFileContents: String
    private var fileURL: URL
    
    init() {
        hostFileContents = ""
        let fileName = "focusmanager-hosts" // Name of the file
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = documentDirectory!.appendingPathComponent(fileName)
    }
    
    func managedHostFileExists() -> Bool{
        // Check if the file exists at the specified URL
        let filePath = self.fileURL.path
        if FileManager.default.fileExists(atPath: filePath) {
            print("Hardlinked host file exists at path: \(filePath)")
            return true
        } else {
            print("Hardlinked host file does not exist at path: \(filePath)")
            return false
        }
    }

    
    func getCurrentHostsFileContents() {
            do {
                self.hostFileContents = try String(contentsOf: self.fileURL, encoding: .utf8)
            } catch {
                print("Error reading the file: \(error)")
            }
    }
    
    func checkIfManagedBlock() -> Bool{
        return self.hostFileContents.contains("# Managed by FocusManager")
    }
    
    func addManagedBlock() {
        let text = self.hostFileContents + "\n\n# Managed by FocusManager\n# End Managed by FocusManager"
        self.writeToFile(text: text)
    }
    
    func writeToFile(text: String){
        do {
            // Write to the file
            try text.write(to: self.fileURL, atomically: false, encoding: .utf8) // Note that atomic needs to be false, otherwise it will copy a new file, breaking the hard link
        } catch {
            print("Error writing to file: \(error)")
        }

    }
    
    func getCurrentManagedBlock() -> Substring {
        // Define the pattern
        let mainString = self.hostFileContents
        // Define the pattern
        let pattern = "(?s)# Managed by FocusManager.*?# End Managed by FocusManager"

        // Create a regular expression object
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(mainString.startIndex..<mainString.endIndex, in: mainString)
            
            // Find matches
            if let match = regex.firstMatch(in: mainString, options: [], range: nsRange) {
                let matchRange = match.range(at: 0)
                if let swiftRange = Range(matchRange, in: mainString) {
                    let extractedSubstring = mainString[swiftRange]
                    return extractedSubstring
                }
            }
        } catch {
            print("Error creating regex: \(error)")
        }
        return ""
    }
    
    func writeToHostsFile(domainsToWrite: [String]) {
        
        var joinedDomains = ""
        if !domainsToWrite.isEmpty{
            joinedDomains = "127.0.0.1" + " " + domainsToWrite.joined(separator: "\n127.0.0.1 ") + "\n"
        }
        
        getCurrentHostsFileContents()
        let text = self.hostFileContents
        let newText = text.replacingOccurrences(of: getCurrentManagedBlock(), with: "# Managed by FocusManager" + "\n" + joinedDomains + "# End Managed by FocusManager")
        
        self.writeToFile(text:newText)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            flushDNSCache()
        }
        
    }
}
