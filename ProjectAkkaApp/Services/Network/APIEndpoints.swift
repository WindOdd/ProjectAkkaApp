//
//  APIEndpoints.swift
//  ProjectAkkaApp
//
//  API 路徑定義
//

import Foundation

enum APIEndpoints {
    case games
    case keywords(gameId: String)
    case chat
    
    func url(baseURL: String) -> URL? {
        switch self {
        case .games:
            return URL(string: "\(baseURL)/api/games")
        case .keywords(let gameId):
            return URL(string: "\(baseURL)/api/keywords/\(gameId)")
        case .chat:
            return URL(string: "\(baseURL)/api/chat")
        }
    }
    
    var method: String {
        switch self {
        case .games, .keywords:
            return "GET"
        case .chat:
            return "POST"
        }
    }
}
