//
//  SharedState.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import Foundation

class SharedState: ObservableObject {
    @Published var domains: [String] = UserDefaults.standard.stringArray(forKey: "domains") ?? []
    @Published var isTimerActive: Bool = false
}
