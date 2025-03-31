//
//  Bet.swift
//  PushBetNotifApp
//
//  Created by Joseph Masri on 3/30/25.
//

import Foundation

struct ProfitableBook: Decodable {
    let odds: Double
    let arb_percent: Double
}

struct Bet: Identifiable, Decodable {
    let id = UUID()
    let player: String
    let prop: String
    let event: String
    let event_time: String
    let league: String
    let prophetx_odds: Double?
    let book_name: String
    let book_odds: Double?
    let arb_percent: Double?
    let timestamp: Date
    let first_volume: Double?
    let last_volume: Double?
    let open_arb_volume: Double?
    
    // ✅ Profitable books dictionary: "BookName" -> ProfitableBook(odds, arb_percent)
    let profitable_books: [String: ProfitableBook]?
}
