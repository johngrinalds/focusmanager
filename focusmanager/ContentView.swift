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
    @EnvironmentObject var sharedState: SharedState
    @EnvironmentObject var hostFileManager: HostsFileManager
    @EnvironmentObject var statusBarController: StatusBarController
    
    @State private var userInputDomain: String = ""
    @State private var showCustomAlert: Bool = false
    @State private var random1: Int = 0
    @State private var random2: Int = 0
    @State private var userAnswer: String = ""
    @State private var userSuspensionRequest: String = ""
    @State private var isAnswerCorrect: Bool = false
    @State private var showTimerInProgressError = false


    
    var body: some View {
        VStack {
            Text("Blocked Domains")
                .padding()
            
            List(sharedState.domains, id: \.self) { domain in
                            Text(domain)
                        }
            .padding()
            
            TextField("www.example.com", text: $userInputDomain)
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
                    hostFileManager.writeDomainsToHostsFile(domainsToWrite: sharedState.domains)
                    cycleWifi()
                    sharedState.isTimerActive = false
                    sharedState.timer?.invalidate()
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
        if userInputDomain != "" && !sharedState.domains.contains(userInputDomain){
            sharedState.domains.append(userInputDomain)
            sharedState.domains.sort()
            UserDefaults.standard.set(sharedState.domains, forKey: "domains")
        }
        userInputDomain = ""
        hostFileManager.writeDomainsToHostsFile(domainsToWrite: sharedState.domains)
    }
    
    func clearDomains(){
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        sharedState.domains = getDomains()
        hostFileManager.writeDomainsToHostsFile(domainsToWrite: sharedState.domains)
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
            hostFileManager.writeDomainsToHostsFile(domainsToWrite: [])
            // Set the suspend period (e.g., 10 minutes)
            let suspendPeriod: TimeInterval = (Double(suspensionTime) ?? 10) * 60
            sharedState.remainingTime = suspendPeriod
            sharedState.isTimerActive = true
            
            sharedState.timer?.invalidate()
            sharedState.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if sharedState.remainingTime > 0 {
                    sharedState.remainingTime -= 1
                    statusBarController.updateTitle(with: timeString(time: sharedState.remainingTime))
                } else {
                    hostFileManager.writeDomainsToHostsFile(domainsToWrite: sharedState.domains)
                    cycleWifi()
                    sharedState.isTimerActive = false
                    sharedState.timer?.invalidate()
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

