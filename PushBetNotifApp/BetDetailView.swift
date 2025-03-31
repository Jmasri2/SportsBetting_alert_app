//
//  BetDetailView.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/30/25.
//

import SwiftUI

struct BetDetailView: View, Identifiable {
    let id = UUID()
    let bet: Bet
    let selectedBook: String

    private func formatOdds(_ odds: Double?) -> String {
        guard let odds = odds else { return "—" }
        let rounded = Int(odds)
        return odds > 0 ? "+\(rounded)" : "\(rounded)"
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "$0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "$" + (formatter.string(from: NSNumber(value: Int(value))) ?? "0")
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        let bookToShow = selectedBook == "All" ? bet.book_name : selectedBook
        let oddsToShow = selectedBook == "All"
            ? bet.book_odds
            : bet.profitable_books?[selectedBook]?.odds

        let arbToShow = selectedBook == "All"
            ? bet.arb_percent
            : bet.profitable_books?[selectedBook]?.arb_percent

        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("📊 Bet Details")
                        .font(.title)
                        .fontWeight(.bold)

                    detailRow("Player", value: bet.player)
                    detailRow("Prop", value: bet.prop)
                    detailRow("Event", value: bet.event)
                    detailRow("League", value: bet.league)

                    Divider()

                    detailRow("Book", value: bookToShow)
                    detailRow("Book Odds", value: formatOdds(oddsToShow))
                    detailRow("ProphetX Odds", value: formatOdds(bet.prophetx_odds))
                    detailRow("Arb %", value: String(format: "%.2f%%", arbToShow ?? 0.0))
                        .foregroundColor(.green)

                    Divider()

                    detailRow("First Volume", value: formatCurrency(bet.first_volume))
                    detailRow("Last Volume", value: formatCurrency(bet.last_volume))
                    detailRow("Open Arb Volume", value: formatCurrency(bet.open_arb_volume))

                    Divider()

                    detailRow("Uploaded", value: formatDateTime(bet.timestamp))
                }
                .padding()
            }
            .navigationTitle("Bet Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
