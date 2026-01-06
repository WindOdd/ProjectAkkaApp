//
//  KeywordInjectionManager.swift
//  ProjectAkkaApp
//
//  contextualStrings 管理 - 遊戲關鍵字注入
//

import Foundation
import Combine

@MainActor
class KeywordInjectionManager: ObservableObject {
    @Published private(set) var keywords: [String] = []
    
    // MARK: - Keyword Operations
    
    /// 清空關鍵字 (進入遊戲前必須呼叫)
    /// 規格書: 確認每次進入遊戲前，contextualStrings 確實被重置為空
    func reset() {
        keywords = []
        print("🔤 關鍵字已清空")
    }
    
    /// 注入新關鍵字
    /// - Parameter newKeywords: 從 API 取得的關鍵字列表
    func inject(keywords newKeywords: [String]) {
        keywords = newKeywords
        print("🔤 注入 \(newKeywords.count) 個關鍵字: \(newKeywords.prefix(5))...")
    }
    
    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        keywords.isEmpty
    }
    
    var count: Int {
        keywords.count
    }
}
