//
//  StatusBarController.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import AppKit
import SwiftUI

class StatusBarController: NSObject, ObservableObject {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var setupComplete: Bool = false

    override init() {
            self.statusBar = NSStatusBar.system
            self.statusItem = NSStatusItem()
        }

    // Move the below setup commands out of the init() function so that the NSStatusItem creation can happen on the main thread
    func setup() {
        if !setupComplete { // Check if the initial setup was already completed, so that reopening the window won't trigger the icon display while timer is active
            setupComplete = true
            DispatchQueue.main.async {
                self.statusItem = self.statusBar.statusItem(withLength: NSStatusItem.variableLength)
                self.updateIcon()
                self.statusItem.button?.image?.size = NSSize(width: 18, height: 18)
                // Observe appearance changes
                self.statusItem.button?.addObserver(self, forKeyPath: "effectiveAppearance", options: .new, context: nil)
            }
        }
    }
    
    func updateTitle(with time: String) {
        DispatchQueue.main.async {
            self.updateIcon()
            self.statusItem.button?.title = time
        }
    }
    
    func revertToIcon() {
        DispatchQueue.main.async {
            self.statusItem.button?.image = NSImage(named: NSImage.Name("16-mac-transparent"))
            self.statusItem.button?.title = ""
        }
    }
    
    private func updateIcon() {
            let appearance = self.statusItem.button?.effectiveAppearance
            let isDarkMode = appearance?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let imageName = isDarkMode ? "16-mac-transparent-dark" : "16-mac-transparent"
            self.statusItem.button?.image = NSImage(named: NSImage.Name(imageName))
        }
        
    // Observe appearance changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "effectiveAppearance" {
            self.updateIcon()
        }
    }
    
    deinit {
        self.statusItem.button?.removeObserver(self, forKeyPath: "effectiveAppearance")
    }
}
