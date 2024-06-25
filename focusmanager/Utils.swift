//
//  Utils.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import Foundation

func getDomains() -> [String]{
    return UserDefaults.standard.stringArray(forKey: "domains") ?? []
}

func printDomains(){
    let temp = UserDefaults.standard.stringArray(forKey: "domains") ?? []
    for item in temp {
        print(item)
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
