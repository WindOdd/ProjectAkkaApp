//
//  GameMenuViewModel.swift
//  ProjectAkkaApp
//
//  遊戲選單邏輯 - 載入遊戲列表、選擇遊戲
//

import Foundation
import Combine

@MainActor
class GameMenuViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isNavigatingToGame = false
    
    private let settingsStore: SettingsStore
    private var httpClient: HTTPClient?
    
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }
    
    // MARK: - Load Games
    
    func loadGames() async {
        guard settingsStore.hasValidServer else {
            errorMessage = "請先設定伺服器連線"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        httpClient = HTTPClient(baseURL: settingsStore.baseURL)
        
        do {
            games = try await httpClient?.fetchGames() ?? []
            print("📋 載入 \(games.count) 款遊戲")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ 載入遊戲失敗: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Game Selection
    
    /// 選擇遊戲 (防止重複點擊)
    func selectGame(_ game: Game) -> Bool {
        guard !isNavigatingToGame else {
            print("⚠️ 防止重複點擊")
            return false
        }
        
        isNavigatingToGame = true
        print("🎮 選擇遊戲: \(game.name)")
        return true
    }
    
    /// 重置導航狀態 (從遊戲返回時呼叫)
    func resetNavigation() {
        isNavigatingToGame = false
    }
}
