//
//  CustomAlertView.swift
//  FocusManager
//
//  Created by John Grinalds on 6/25/24.
//

import SwiftUI

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
