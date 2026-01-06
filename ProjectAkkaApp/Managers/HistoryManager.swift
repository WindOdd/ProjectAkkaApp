//
//  HistoryManager.swift
//  ProjectAkkaApp
//
//  對話紀錄管理 - 8輪上限, FIFO
//

import Foundation
import Combine

class HistoryManager: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    
    private let maxRounds = Constants.History.maxRounds
    
    // MARK: - History Operations
    
    /// 新增一組對話 (user + assistant)
    /// - Parameters:
    ///   - userContent: 使用者輸入內容
    ///   - assistantContent: 助手回應內容
    ///   - intent: 意圖標籤
    func addExchange(userContent: String, assistantContent: String, intent: String?) {
        let userMessage = ChatMessage(role: "user", content: userContent, intent: nil)
        let assistantMessage = ChatMessage(role: "assistant", content: assistantContent, intent: intent)

        messages.append(userMessage)
        messages.append(assistantMessage)

        // FIFO: 超過上限移除最舊的一組（優化：只在超過時才 trim）
        if messages.count > maxRounds * 2 {
            messages.removeFirst(2)
            print("📝 History 移除最舊的一組對話 (FIFO)")
        }

        print("📝 History 新增對話，目前共 \(messages.count / 2) 輪")
    }

    /// 清空所有歷史 (Session 銷毀時呼叫)
    func clear() {
        messages.removeAll()
        print("📝 History 已清空")
    }
    
    // MARK: - Computed Properties
    
    var roundCount: Int {
        messages.count / 2
    }
    
    var isEmpty: Bool {
        messages.isEmpty
    }
}
