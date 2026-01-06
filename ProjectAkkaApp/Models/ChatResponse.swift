//
//  ChatResponse.swift
//  ProjectAkkaApp
//
//  POST /api/chat 回應
//

import Foundation

struct ChatResponse: Codable {
    let response: String
    let intent: String
    let source: String     // "cloud_rag"
}
