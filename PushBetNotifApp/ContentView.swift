//
//  ContentView.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BetsViewModel()
    @State private var selectedBet: Bet? = nil
    @State private var selectedLeague: String = "All"
    @State private var selectedBook: String = "All"
    @State private var sortBy: String = "arb"

    let leagues = ["All", "NFL", "NBA", "MLB", "NHL", "NCAAF", "NCAAB", "Soccer", "Tennis", "Golf", "UFC"]
    let books = ["All", "DraftKings", "Bet365", "BetMGM", "ESPN BET", "FanDuel", "Hard Rock",
                 "BetRivers", "Caesars", "Fanatics", "Fliff", "PointsBet", "Pinnacle",
                 "Circa", "BookMaker", "BetOnline", "Bet105"]
    let sortOptions = ["arb", "timestamp"]

    var filteredBets: [Bet] {
        viewModel.bets
            .filter { bet in
                let matchesLeague = selectedLeague == "All" || bet.league == selectedLeague
                let matchesBook = selectedBook == "All"
                    || bet.book_name == selectedBook
                    || bet.profitable_books?[selectedBook] != nil

                let arb = selectedBook == "All"
                    ? bet.arb_percent ?? 0
                    : bet.profitable_books?[selectedBook]?.arb_percent ?? 0

                return matchesLeague && matchesBook && arb > 1
            }
            .sorted {
                if sortBy == "timestamp" {
                    return $0.timestamp > $1.timestamp
                } else {
                    let a = selectedBook == "All"
                        ? $0.arb_percent ?? 0
                        : $0.profitable_books?[selectedBook]?.arb_percent ?? 0
                    let b = selectedBook == "All"
                        ? $1.arb_percent ?? 0
                        : $1.profitable_books?[selectedBook]?.arb_percent ?? 0
                    return a > b
                }
            }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)

                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Text("🔥 Arbitrage Bets")
                            .font(.title)
                            .bold()
                            .padding(.top, 2) // adjust as needed

                        HStack {
                            Picker("League", selection: $selectedLeague) {
                                ForEach(leagues, id: \.self) { league in
                                    Text(league).tag(league)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())

                            Picker("Book", selection: $selectedBook) {
                                ForEach(books, id: \.self) { book in
                                    Text(book).tag(book)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())

                            Picker("Sort By", selection: $sortBy) {
                                Text("Arb %").tag("arb")
                                Text("Most Recent").tag("timestamp")
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.horizontal)
                    }


                    if viewModel.isLoading {
                        ProgressView("Loading Bets...")
                    } else if filteredBets.isEmpty {
                        Text("No arbitrage bets found.")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredBets) { bet in
                                    Button {
                                        selectedBet = bet
                                    } label: {
                                        BetCardView(bet: bet, selectedBook: selectedBook)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
//            .navigationTitle("🔥 Arbitrage Bets")
//            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchBets()
            }
            .sheet(item: $selectedBet) { bet in
                BetDetailView(bet: bet, selectedBook: selectedBook)
            }
        }
        .navigationBarHidden(true)
    }
}

struct BetCardView: View {
    let bet: Bet
    let selectedBook: String

    var body: some View {
        let arb = selectedBook == "All"
            ? bet.arb_percent ?? 0.0
            : bet.profitable_books?[selectedBook]?.arb_percent ?? 0.0

        let odds = selectedBook == "All"
            ? bet.book_odds
            : bet.profitable_books?[selectedBook]?.odds

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(bet.player)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "%.2f%%", arb))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            Text(bet.prop)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(bet.event)
                .font(.footnote)
                .foregroundColor(.gray)

            if let odds = odds {
                let bookLabel = selectedBook == "All" ? bet.book_name : selectedBook
                Text("\(bookLabel) Odds: \(odds > 0 ? "+\(Int(odds))" : "\(Int(odds))")")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }

        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
