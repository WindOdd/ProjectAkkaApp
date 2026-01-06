//
//  Game.swift
//  ProjectAkkaApp
//
//  遊戲資料模型 - 對應 GET /api/games 回應
//

import Foundation

struct Game: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let enableSttInjection: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case enableSttInjection = "enable_stt_injection"
    }
}

// MARK: - API Response Wrapper
struct GamesResponse: Codable {
    let games: [Game]
}
