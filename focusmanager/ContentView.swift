//
//  ContentView.swift
//  focusmanager
//
//  Created by John Grinalds on 6/13/24.
//
// Backup hosts file: sudo cp /etc/hosts /etc/hosts.backup
// Hardlink the hosts file with: sudo ln -f /Users/johngrinalds/Library/Containers/com.example.focusmanager/Data/Documents/focusmanager-hosts /etc/hosts
// Give the hardlink the needed permissions: sudo chown johngrinalds:staff focusmanager-hosts

import Cocoa
import SwiftUI
import Foundation

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SharedState())
    }
}

