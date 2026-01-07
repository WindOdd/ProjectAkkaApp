//
//  HistoryManager.swift
//  ProjectAkkaApp
//
//  對話紀錄管理 - 8輪上限, FIFO
//

import Foundation
import Combine

@MainActor
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

        // FIFO: 確保移除完整的對話輪
        trimToMaxRounds()

        print("📝 History 新增對話，目前共 \(roundCount) 輪")
    }

    /// 確保歷史記錄不超過上限，移除完整的對話輪
    private func trimToMaxRounds() {
        // 安全檢查：確保訊息數量是偶數
        if messages.count % 2 != 0 {
            print("⚠️ 警告：訊息數量不是偶數(\(messages.count))，移除最後一則以保持配對")
            messages.removeLast()
        }

        // 移除最舊的完整對話輪
        while messages.count > maxRounds * 2 {
            messages.removeFirst(2)
            print("📝 History 移除最舊的一組對話 (FIFO)")
        }
    }

    /// 清空所有歷史 (Session 銷毀時呼叫)
    func clear() {
        messages.removeAll()
        print("📝 History 已清空")
    }

    // MARK: - Computed Properties

    var roundCount: Int {
        // 安全的輪數計算
        messages.count / 2
    }

    var isEmpty: Bool {
        messages.isEmpty
    }

    /// 檢查訊息配對是否正確
    var isProperlyPaired: Bool {
        messages.count % 2 == 0
    }
}
