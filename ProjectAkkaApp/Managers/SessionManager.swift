//
//  SessionManager.swift
//  ProjectAkkaApp
//
//  Session 生命週期管理 - 進入遊戲(生成) <-> 離開遊戲(銷毀)
//

import Foundation
import Combine

@MainActor
class SessionManager: ObservableObject {
    @Published private(set) var sessionId: String?
    @Published private(set) var currentGame: Game?
    @Published private(set) var isInGame: Bool = false
    
    // MARK: - Session Lifecycle
    
    /// 開始新的遊戲 Session
    /// - Parameter game: 選擇的遊戲
    func startSession(game: Game) {
        sessionId = UUID().uuidString
        currentGame = game
        isInGame = true
        print("🎮 Session 開始: \(sessionId ?? "nil") - 遊戲: \(game.name)")
    }
    
    /// 結束當前 Session
    func endSession() {
        print("🎮 Session 結束: \(sessionId ?? "nil")")
        sessionId = nil
        currentGame = nil
        isInGame = false
    }
    
    // MARK: - Computed Properties
    
    var gameName: String {
        currentGame?.name ?? ""
    }
    
    var enableSttInjection: Bool {
        currentGame?.enableSttInjection ?? false
    }
}
