//
//  HostsFileManager.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import Foundation

class HostsFileManager: ObservableObject {
    private var hostsFileContents: String
    private var fileURL: URL
    
    init() {
        hostsFileContents = ""
        let fileName = "focusmanager-hosts" // Name of the file
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        fileURL = documentDirectory!.appendingPathComponent(fileName)
    }
    
    func fileExists() -> Bool{
        let filePath = self.fileURL.path
        if FileManager.default.fileExists(atPath: filePath) {
            print("Hardlinked hosts file exists at path: \(filePath)")
            return true
        } else {
            print("Hardlinked hosts file does not exist at path: \(filePath)")
            return false
        }
    }

    /// Gets contents of entire file
    func getCurrentFileContents() {
            do {
                self.hostsFileContents = try String(contentsOf: self.fileURL, encoding: .utf8)
            } catch {
                print("Error reading the file: \(error)")
            }
    }
    
    func managedSectionExists() -> Bool{
        return self.hostsFileContents.contains("# Managed by FocusManager")
    }
    
    func addManagedSection() {
        let text = self.hostsFileContents + "\n\n# Managed by FocusManager\n# End Managed by FocusManager"
        self.writeToFile(text: text)
    }
    
    
    /// Returns both the section bookends and section contents
    func getCurrentManagedSection() -> Substring {
        let mainString = self.hostsFileContents
        let pattern = "(?s)# Managed by FocusManager.*?# End Managed by FocusManager"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsRange = NSRange(mainString.startIndex..<mainString.endIndex, in: mainString)
            
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
    
    func writeToFile(text: String){
        do {
            // Note that atomic needs to be false, otherwise it will copy a new file, breaking the hard link
            try text.write(to: self.fileURL, atomically: false, encoding: .utf8)
        } catch {
            print("Error writing to file: \(error)")
        }
        
    }
    
    func writeDomainsToHostsFile(domainsToWrite: [String]) {
        var joinedDomains = ""
        if !domainsToWrite.isEmpty{
            joinedDomains = "127.0.0.1" + " " + domainsToWrite.joined(separator: "\n127.0.0.1 ") + "\n"
        }
        
        getCurrentFileContents()
        let text = self.hostsFileContents
        let updatedText = text.replacingOccurrences(of: getCurrentManagedSection(), with: "# Managed by FocusManager" + "\n" + joinedDomains + "# End Managed by FocusManager")
        
        self.writeToFile(text:updatedText)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            flushDNSCache()
        }
        
    }
}
