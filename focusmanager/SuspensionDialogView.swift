//
//  SuspensionDialogView.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import SwiftUI

struct SuspensionDialogView: View {
    @Binding var show: Bool
    @Binding var randomInt1: Int
    @Binding var randomInt2: Int
    @Binding var userAnswer: String
    @Binding var userSuspensionRequest: String
    @Binding var isAnswerCorrect: Bool
    let suspendClosure: (String) -> Void // Closure to be executed on confirmation

    var body: some View {
        VStack {
            Text("Confirmation")
                .font(.headline).padding()
            Text("What is \(randomInt1) + \(randomInt2)?")
            TextField("Your answer", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Text("How many minutes to suspend for?")
            TextField("Minutes", text: $userSuspensionRequest)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    submissionHandler()
                }
            HStack {
                Button("Submit") {
                    submissionHandler()
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

    private func submissionHandler() {
        if Int(userAnswer) == randomInt1 + randomInt2 {
            isAnswerCorrect = true
            print("Answer correct")
            suspendClosure(userSuspensionRequest) // Call the passed function
            show = false
        } else {
            isAnswerCorrect = false
            print("Incorrect answer")
        }
    }
}
