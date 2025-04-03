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
            Spacer()

            Text("Sign in to continue")
                .font(.title2)
                .padding()

            SignInWithAppleButton(
                onRequest: { request in
                    print("🟡 Apple Sign-In: Request started")
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    print("🟢 Apple Sign-In: Completion triggered")
                    handleAuth(result: result)
                }
            )
            .frame(height: 50)
            .signInWithAppleButtonStyle(.black)
            .padding()

            Spacer()
        }
    }

    // 🔐 Apple Sign-In Handling
    private func handleAuth(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("❌ Failed to extract Apple credential")
                return
            }

            // ✅ Save Apple user ID (used for revocation checks later)
            let appleUserID = appleIDCredential.user
            UserDefaults.standard.set(appleUserID, forKey: "appleUserID")

            guard let tokenData = appleIDCredential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8) else {
                print("❌ identityToken was nil — possibly misconfigured app entitlement or Apple sign-in failed silently.")
                return
            }

            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: tokenString,
                rawNonce: "" // Add nonce later for extra security if needed
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("❌ Firebase sign-in error: \(error.localizedDescription)")
                    return
                }

                if let uid = Auth.auth().currentUser?.uid {
                    UserDefaults.standard.set(uid, forKey: "firebaseUID")
                    UserDefaults.standard.synchronize()
                    print("✅ Saved Firebase UID: \(uid)")
                }

                print("✅ Signed in with Apple!")
                onSignedIn()
            }

        case .failure(let error):
            print("❌ Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
}
