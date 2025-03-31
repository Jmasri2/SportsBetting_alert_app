//
//  PushBetNotifApp.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/31/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

@main
struct PushBetNotifApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSignedIn = false
    @State private var firebaseInitialized = false

    init() {
        FirebaseApp.configure()
        print("✅ Firebase configured")
    }

    var body: some Scene {
        WindowGroup {
            if firebaseInitialized {
                if isSignedIn {
                    ContentView()
                        .onAppear {
                            // ✅ Save UID if not already stored
                            if let uid = Auth.auth().currentUser?.uid,
                               UserDefaults.standard.string(forKey: "firebaseUID") != uid {
                                UserDefaults.standard.set(uid, forKey: "firebaseUID")
                                UserDefaults.standard.synchronize()
                                print("✅ Saved UID at app launch: \(uid)")
                            }
                        }
                } else {
                    LoginView {
                        isSignedIn = true
                    }
                }
            } else {
                ProgressView("Initializing Firebase...")
                    .onAppear {
                        if FirebaseApp.app() != nil {
                            firebaseInitialized = true
                            isSignedIn = Auth.auth().currentUser != nil
                        }
                    }
            }
        }
    }

    
}


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Request permission to show notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("📲 Notification permission granted: \(granted)")
            if let error = error {
                print("❌ Error requesting notification permission: \(error)")
            }

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
                print("✅ Registered for remote notifications")
            }
        }

        // 🔁 Only fetch and save token if we don't already have one
        if UserDefaults.standard.string(forKey: "fcmToken") == nil {
            Messaging.messaging().token { token, error in
                if let token = token {
                    print("🪪 Initial FCM token (saved): \(token)")
                    UserDefaults.standard.set(token, forKey: "fcmToken")
                    UserDefaults.standard.synchronize()
                } else if let error = error {
                    print("❌ Error fetching FCM token: \(error.localizedDescription)")
                }
            }
        } else {
            print("🪪 FCM token already saved: \(UserDefaults.standard.string(forKey: "fcmToken")!)")
        }

        return true
    }


    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("📬 APNs token received")

        // ✅ Now safely fetch and send the token to your backend
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM token error: \(error.localizedDescription)")
            } else if let token = token {
                print("🪪 FCM token: \(token)")
                
                // 🔐 Save token persistently so we don't request it every launch
                UserDefaults.standard.set(token, forKey: "fcmToken")
                UserDefaults.standard.synchronize()
                
                self.sendTokenToBackend(token)
            }
        }
    }

    func sendTokenToBackend(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid,
              let url = URL(string: "https://exchangesvssportsbooks.com/api/register_token") else { return }

        let payload: [String: Any] = [
            "uid": uid,
            "fcm_token": token
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Failed to register token: \(error)")
                } else {
                    print("✅ Token registered to backend with UID")
                }
            }.resume()
        } catch {
            print("❌ JSON encode error: \(error)")
        }
    }




    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🪪 Delegate FCM token: \(fcmToken ?? "nil")")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
