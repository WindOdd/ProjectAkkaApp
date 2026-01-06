//
//  ChatRequest.swift
//  ProjectAkkaApp
//
//  POST /api/chat 請求體
//

import Foundation

struct ChatRequest: Codable {
    let tableId: String
    let sessionId: String
    let gameContext: GameContext
    let userInput: String
    let history: [ChatMessage]
    
    struct GameContext: Codable {
        let gameName: String
        
        enum CodingKeys: String, CodingKey {
            case gameName = "game_name"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case tableId = "table_id"
        case sessionId = "session_id"
        case gameContext = "game_context"
        case userInput = "user_input"
        case history
    }
}
