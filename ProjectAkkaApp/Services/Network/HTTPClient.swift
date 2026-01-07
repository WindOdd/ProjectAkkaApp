//
//  HTTPClient.swift
//  ProjectAkkaApp
//
//  RESTful API 請求封裝
//

import Foundation

class HTTPClient {
    private let baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    // MARK: - GET /api/games
    
    func fetchGames() async throws -> [Game] {
        guard let url = APIEndpoints.games.url(baseURL: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        
        let gamesResponse = try JSONDecoder().decode(GamesResponse.self, from: data)
        return gamesResponse.games
    }
    
    // MARK: - GET /api/keywords/{game_id}
    
    func fetchKeywords(gameId: String) async throws -> [String] {
        guard let url = APIEndpoints.keywords(gameId: gameId).url(baseURL: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        
        let keywordsResponse = try JSONDecoder().decode(KeywordsResponse.self, from: data)
        return keywordsResponse.keywords
    }
    
    // MARK: - POST /api/chat
    
    func sendChat(request: ChatRequest) async throws -> ChatResponse {
        guard let url = APIEndpoints.chat.url(baseURL: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Constants.Timeout.chatRequestRead
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)
        
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }
    
    // MARK: - 測試連線 (Fail Fast)
    
    func testConnection() async throws -> Bool {
        guard let url = APIEndpoints.games.url(baseURL: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = Constants.Timeout.connectionTestRead
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return true
    }
    
    // MARK: - Private
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
