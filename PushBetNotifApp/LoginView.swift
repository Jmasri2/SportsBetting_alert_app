//
//  LoginView.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/31/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    var onSignedIn: () -> Void

    var body: some View {
        VStack {
            Text("Sign in to continue")
                .font(.title2)
                .padding()

            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: handleAuth
            )
            .frame(height: 50)
            .signInWithAppleButtonStyle(.black)
            .padding()
        }
    }

    private func handleAuth(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8) else {
                print("❌ Failed to extract identity token string")
                return
            }

            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: tokenString,
                rawNonce: ""  // You can add real nonce later for extra security
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("❌ Firebase sign-in error: \(error.localizedDescription)")
                    return
                }

                // ✅ Save UID to UserDefaults
                if let uid = Auth.auth().currentUser?.uid {
                    UserDefaults.standard.set(uid, forKey: "firebaseUID")
                    UserDefaults.standard.synchronize()
                    print("✅ Saved UID: \(uid)")
                }

                print("✅ Signed in with Apple!")
                onSignedIn()  // 🚀 Trigger the switch to ContentView
            }


        case .failure(let error):
            print("❌ Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
}
