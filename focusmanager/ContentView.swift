//
//  ContentView.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//
// Hardlink the hosts file with: sudo ln -f /Users/johngrinalds/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts /etc/hosts
// osascript -e 'quit app "Chrome"'

import Cocoa
import SwiftUI
import Foundation

class SharedState: ObservableObject {
    @Published var domains: [String] = UserDefaults.standard.stringArray(forKey: "domains") ?? []
}

struct ContentView: View {
    @State private var userInput: String = ""
    @EnvironmentObject var sharedState: SharedState
    @State private var showCustomAlert: Bool = false
    @State private var random1: Int = 0
    @State private var random2: Int = 0
    @State private var userAnswer: String = ""
    @State private var userSuspensionRequest: String = ""
    @State private var isAnswerCorrect: Bool = false
    
    @State private var remainingTime: TimeInterval = 0
    @State private var isTimerActive: Bool = false
    @State private var timer: Timer? = nil
    @StateObject private var statusBarController = StatusBarController()
    
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
                    if isTimerActive{
                        showTimerInProgressError = true
                    } else {
                        generateRandomNumbers()
                        showCustomAlert = true
                    }
                }.padding()
                
                Button("Resume Blocking") {
                    writeToHostsFile(domainsToWrite: sharedState.domains)
                    cycleWifi()
                    isTimerActive = false
                    timer?.invalidate()
                    statusBarController.updateTitle(with: "Time's up")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        statusBarController.revertToIcon()
                    }
                }.padding()
            }
        }
        .alert(isPresented: $showTimerInProgressError) {
                    Alert(
                        title: Text("Error"),
                        message: Text("Blocking Suspension in Progress"),
                        dismissButton: .default(Text("OK"))
                    )
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
        writeToHostsFile(domainsToWrite: sharedState.domains)
    }
    
    func clearDomains(){
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        sharedState.domains = getDomains()
        writeToHostsFile(domainsToWrite: sharedState.domains)
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
            writeToHostsFile(domainsToWrite: [])
            // Set the suspend period (e.g., 10 minutes)
            let suspendPeriod: TimeInterval = (Double(suspensionTime) ?? 10) * 60
            remainingTime = suspendPeriod
            isTimerActive = true
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if remainingTime > 0 {
                    remainingTime -= 1
                    statusBarController.updateTitle(with: timeString(time: remainingTime))
                } else {
                    writeToHostsFile(domainsToWrite: sharedState.domains)
                    cycleWifi()
                    isTimerActive = false
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

    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(named: NSImage.Name("16-mac"))
        statusItem.button?.image?.size = NSSize(width: 18, height: 18)
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

func writeToHostsFile(domainsToWrite: [String]) {
    // Text to write to the file
    var joinedDomains = ""
    if !domainsToWrite.isEmpty{
        joinedDomains = "127.0.0.1" + " " + domainsToWrite.joined(separator: "\n127.0.0.1 ")
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

