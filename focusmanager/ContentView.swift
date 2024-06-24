//
//  ContentView.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//
// Backup hosts file: sudo cp /etc/hosts /etc/hosts.backup
// Hardlink the hosts file with: sudo ln -f /Users/johngrinalds/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts /etc/hosts
// Give the hardlink the needed permissions: sudo chown johngrinalds:staff focusmanager-hosts

//sudo cp /etc/hosts /etc/hosts.backup
//
//sudo ln -f /etc/hosts /Users/<USER>/Library/Containers/com.johngrinalds.focusmanager/Data/Documents/focusmanager-hosts
//
//sudo chown <USER>:staff /Users/<USER>/Library/Containers/com.johngrinalds.focusmanager/Data/Documents/focusmanager-hosts

import Cocoa
import SwiftUI
import Foundation

class SharedState: ObservableObject {
    @Published var domains: [String] = UserDefaults.standard.stringArray(forKey: "domains") ?? []
    @Published var isTimerActive: Bool = false
}

struct ContentView: View {
    @State private var userInput: String = ""
    @EnvironmentObject var sharedState: SharedState
    @EnvironmentObject var hostFileManager: HostFileManager
    @EnvironmentObject var statusBarController: StatusBarController
    @State private var showCustomAlert: Bool = false
    @State private var random1: Int = 0
    @State private var random2: Int = 0
    @State private var userAnswer: String = ""
    @State private var userSuspensionRequest: String = ""
    @State private var isAnswerCorrect: Bool = false
    
    @State private var remainingTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    
    @State private var showTimerInProgressError = false


    
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
                            .onSubmit {
                                addDomain()
                            }
            HStack {
                Button("Add Domain") {
                    addDomain()
                }.padding()
                
                Button("Suspend Blocking") {
                    if sharedState.isTimerActive{
                        showTimerInProgressError = true
                    } else {
                        generateRandomNumbers()
                        showCustomAlert = true
                    }
                }.padding()
                
                Button("Resume Blocking") {
                    hostFileManager.writeToHostsFile(domainsToWrite: sharedState.domains)
                    cycleWifi()
                    sharedState.isTimerActive = false
                    timer?.invalidate()
                    statusBarController.updateTitle(with: "Time's up")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        statusBarController.revertToIcon()
                    }
                }.padding()
            }
        }
        .alert(Text("Error"), isPresented: $showTimerInProgressError) {
            Button("OK") {
            }
        } message: {
            Text("Blocking Suspension in Progress")
        }
        .overlay(
            CustomAlertView(show: $showCustomAlert,
                            random1: $random1,
                            random2: $random2,
                            userAnswer: $userAnswer,
                            userSuspensionRequest: $userSuspensionRequest,
                            isAnswerCorrect: $isAnswerCorrect,
                            suspendClosure: suspend)
                        .frame(width: 300, height: 300)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .opacity(showCustomAlert ? 1 : 0)
                )
    }
    
    func addDomain(){
        if userInput != "" && !sharedState.domains.contains(userInput){
            sharedState.domains.append(userInput)
            sharedState.domains.sort()
            UserDefaults.standard.set(sharedState.domains, forKey: "domains")
        }
        userInput = ""
        hostFileManager.writeToHostsFile(domainsToWrite: sharedState.domains)
    }
    
    func clearDomains(){
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        sharedState.domains = getDomains()
        hostFileManager.writeToHostsFile(domainsToWrite: sharedState.domains)
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func suspend(suspensionTime: String){
        if suspensionTime == "infinity" { // This is the "cheat code" to remove all domains from the blocklist
            print("Clearing all domains indefinitely")
            clearDomains()
        } else {
            print("Suspending for \(suspensionTime) minutes")
            hostFileManager.writeToHostsFile(domainsToWrite: [])
            // Set the suspend period (e.g., 10 minutes)
            let suspendPeriod: TimeInterval = (Double(suspensionTime) ?? 10) * 60
            remainingTime = suspendPeriod
            sharedState.isTimerActive = true
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if remainingTime > 0 {
                    remainingTime -= 1
                    statusBarController.updateTitle(with: timeString(time: remainingTime))
                } else {
                    hostFileManager.writeToHostsFile(domainsToWrite: sharedState.domains)
                    cycleWifi()
                    sharedState.isTimerActive = false
                    timer?.invalidate()
                    statusBarController.updateTitle(with: "Time's up")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        statusBarController.revertToIcon()
                    }
                    
                }
            }
        }
    }
    
    func generateRandomNumbers() {
        random1 = Int.random(in: 1...10)
        random2 = Int.random(in: 1...10)
    }
    
}

struct CustomAlertView: View {
    @Binding var show: Bool
    @Binding var random1: Int
    @Binding var random2: Int
    @Binding var userAnswer: String
    @Binding var userSuspensionRequest: String
    @Binding var isAnswerCorrect: Bool
    let suspendClosure: (String) -> Void // Closure to be executed on confirmation

    var body: some View {
        VStack {
            Text("Confirmation")
                .font(.headline).padding()
            Text("What is \(random1) + \(random2)?")
            TextField("Your answer", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Text("How many minutes to suspend for?")
            TextField("Minutes", text: $userSuspensionRequest)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    if checkAnswer() {
                        // Action to perform when the answer is correct
                        isAnswerCorrect = true
                        print("Answer correct")
                        suspendClosure(userSuspensionRequest) // Call the passed function
                        show = false
                    } else {
                        isAnswerCorrect = false
                        print("Incorrect answer")
                        // Optionally, show an error message
                    }
                }
            HStack {
                Button("Submit") {
                    if checkAnswer() {
                        // Action to perform when the answer is correct
                        isAnswerCorrect = true
                        print("Answer correct")
                        suspendClosure(userSuspensionRequest) // Call the passed function
                        show = false
                    } else {
                        isAnswerCorrect = false
                        print("Incorrect answer")
                        // Optionally, show an error message
                    }
                }
                .padding()
                Button("Cancel") {
                    show = false
                }
                .padding()
            }
        }
        .padding()
    }

    private func checkAnswer() -> Bool {
        return Int(userAnswer) == random1 + random2
    }
}

class StatusBarController: ObservableObject {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var setupComplete: Bool = false

    init() {
            self.statusBar = NSStatusBar.system
            self.statusItem = NSStatusItem()
        }

    // Move the below setup commands out of the init() function so that the NSStatusItem creation can happen on the main thread
    func setup() {
        if !setupComplete { // Check if the initial setup was already completed, so that reopening the window won't trigger the icon display while timer is active
            setupComplete = true
            DispatchQueue.main.async {
                self.statusItem = self.statusBar.statusItem(withLength: NSStatusItem.variableLength)
                self.statusItem.button?.image = NSImage(named: NSImage.Name("16-mac"))
                self.statusItem.button?.image?.size = NSSize(width: 18, height: 18)
            }
        }
    }
    
    func updateTitle(with time: String) {
        DispatchQueue.main.async {
            self.statusItem.button?.image = nil
            self.statusItem.button?.title = time
        }
    }
    
    func revertToIcon() {
        DispatchQueue.main.async {
            self.statusItem.button?.image = NSImage(named: NSImage.Name("16-mac"))
            self.statusItem.button?.title = ""
        }
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

func flushDNSCache() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
        process.arguments = ["-flushcache"]

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

func cycleWifi() {
    // osascript -e 'quit app "Chrome"'
    // Don't think this can be run from the app's permissions
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["shortcuts://run-shortcut?name=wifi"]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                print("Successfully run Wifi Cycle Shortcut.")
            } else {
                print("Failed to run Shortcut.")
            }
        } catch {
            print("Error running the process: \(error)")
        }
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SharedState())
    }
}

