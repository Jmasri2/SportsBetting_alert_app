//
//  BetsViewModel.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/30/25.
//

import SwiftUI
import Combine

class BetsViewModel: ObservableObject {
    @Published var bets: [Bet] = []
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()

    func fetchBets(book: String = "All") {
        let urlString = "https://exchangesvssportsbooks.com/api/arb_bets"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }

        isLoading = true
        let fetchStartTime = Date() // 🔸 Track when the fetch started

        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        decoder.dateDecodingStrategy = .formatted(formatter)

        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [Bet].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                // 🔸 Make sure loading lasts at least 0.6 seconds
                let elapsed = Date().timeIntervalSince(fetchStartTime)
                let delay = max(0.6 - elapsed, 0)

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.isLoading = false
                    if case let .failure(error) = completion {
                        print("❌ Error fetching bets: \(error)")
                    }
                }
            }, receiveValue: { [weak self] bets in
                print("✅ Successfully fetched \(bets.count) bets")
                self?.bets = bets
            })
            .store(in: &cancellables)
    }

}
