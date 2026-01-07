//
//  ChatBubble.swift
//  ProjectAkkaApp
//
//  對話氣泡元件 - 用於顯示 user/assistant 訊息
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    
    private var isUser: Bool {
        message.role == "user"
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.blue.opacity(0.15) : Color(.systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                
                // Intent 標籤 (僅 assistant 顯示)
                if !isUser, let intent = message.intent {
                    Text(intentLabel(intent))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
    
    private func intentLabel(_ intent: String) -> String {
        switch intent {
        case "RULES":
            return "📖 規則查詢"
        case "GENERAL":
            return "💬 一般對話"
        default:
            return intent
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubble(message: ChatMessage(role: "user", content: "卡卡頌怎麼玩？"))
        ChatBubble(message: ChatMessage(role: "assistant", content: "卡卡頌是一款經典的板塊放置遊戲...", intent: "RULES"))
        ChatBubble(message: ChatMessage(role: "user", content: "農夫怎麼計分？"))
        ChatBubble(message: ChatMessage(role: "assistant", content: "農夫在遊戲結束時，每提供給一個完整城市...", intent: "RULES"))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
