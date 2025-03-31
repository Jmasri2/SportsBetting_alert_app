//
//  NotificationPreferencesView.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/31/25.
//

import SwiftUI
import FirebaseMessaging

struct NotificationSettingsView: View {
    @Binding var isPresented: Bool
    let books: [String]

    @State private var selectedBooks: Set<String> = []
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var token: String = UserDefaults.standard.string(forKey: "fcmToken") ?? ""

    var allBooks: [String] {
        return ["Best Odds Book"] + books
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select books to receive notifications from")) {
                    ForEach(allBooks, id: \.self) { book in
                        Toggle(isOn: Binding(
                            get: { selectedBooks.contains(book) },
                            set: { isOn in
                                if isOn {
                                    selectedBooks.insert(book)
                                } else {
                                    selectedBooks.remove(book)
                                }
                            }
                        )) {
                            Text(book)
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                Button(action: submitPreferences) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Save Preferences")
                            .fontWeight(.bold)
                    }
                }
                .disabled(isSubmitting)
            }
            .navigationBarTitle("Notification Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .onAppear {
                initializeTokenAndLoadPreferences()
            }
        }
    }

    private func initializeTokenAndLoadPreferences() {
        // If already saved, use it
        if !token.isEmpty {
            loadPreferences()
            return
        }

        // Otherwise fetch and save
        Messaging.messaging().token { newToken, error in
            guard let newToken = newToken, error == nil else {
                self.errorMessage = "Failed to get FCM token"
                return
            }
            self.token = newToken
            UserDefaults.standard.set(newToken, forKey: "fcmToken")
            UserDefaults.standard.synchronize()
            loadPreferences()
        }
    }

    private func loadPreferences() {
        guard let uid = UserDefaults.standard.string(forKey: "firebaseUID") else {
            self.errorMessage = "Missing user ID"
            return
        }

        guard let url = URL(string: "https://exchangesvssportsbooks.com/api/get_subscriptions?uid=\(uid)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decoded = try? JSONDecoder().decode([String: [String]].self, from: data),
                   let books = decoded["books"] {
                    DispatchQueue.main.async {
                        self.selectedBooks = Set(books)
                    }
                }
            }
        }.resume()
    }


    private func submitPreferences() {
        isSubmitting = true
        errorMessage = nil

        guard let uid = UserDefaults.standard.string(forKey: "firebaseUID") else {
            self.errorMessage = "Missing user ID"
            self.isSubmitting = false
            return
        }

        let url = URL(string: "https://exchangesvssportsbooks.com/api/update_subscriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "uid": uid,
            "books": Array(selectedBooks)
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            self.errorMessage = "Encoding error"
            self.isSubmitting = false
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                if error != nil {
                    self.errorMessage = "Failed to save preferences"
                } else {
                    self.isPresented = false
                }
            }
        }.resume()
    }

}
