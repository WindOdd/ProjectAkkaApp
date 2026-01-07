//
//  KeywordsResponse.swift
//  ProjectAkkaApp
//
//  GET /api/keywords/{game_id} 回應
//

import Foundation

struct KeywordsResponse: Codable {
    let gameId: String
    let keywords: [String]
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case keywords
    }
}
