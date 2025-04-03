//
//  AuthViewModel.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 4/2/25.
//

import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = Auth.auth().currentUser != nil

    init() {
        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isSignedIn = (user != nil)
            }
        }
    }
}
