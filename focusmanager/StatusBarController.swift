//
//  StatusBarController.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import AppKit
import SwiftUI

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
