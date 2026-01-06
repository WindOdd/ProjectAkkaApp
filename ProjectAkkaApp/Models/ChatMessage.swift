//
//  ChatMessage.swift
//  ProjectAkkaApp
//
//  對話訊息模型 - 用於 History 管理
//

import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: String       // "user" | "assistant"
    let content: String
    let intent: String?    // "RULES" | null
    
    init(role: String, content: String, intent: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.intent = intent
    }
    
    enum CodingKeys: String, CodingKey {
        case role, content, intent
    }
    
    // Custom decoding (id is not from API)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
        self.intent = try container.decodeIfPresent(String.self, forKey: .intent)
    }
    
    // Custom encoding (exclude id)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(intent, forKey: .intent)
    }
}
