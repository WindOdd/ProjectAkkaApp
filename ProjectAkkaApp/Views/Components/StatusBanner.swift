//
//  StatusBanner.swift
//  ProjectAkkaApp
//
//  連線狀態提示
//

import SwiftUI

struct StatusBanner: View {
    let status: Status
    
    enum Status {
        case connected
        case disconnected
        case searching
        
        var message: String {
            switch self {
            case .connected: return "已連線"
            case .disconnected: return "未連線"
            case .searching: return "搜尋中..."
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "wifi"
            case .disconnected: return "wifi.slash"
            case .searching: return "wifi.exclamationmark"
            }
        }
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .disconnected: return .red
            case .searching: return .orange
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
            Text(status.message)
        }
        .font(.caption)
        .foregroundColor(status.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .cornerRadius(20)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusBanner(status: .connected)
        StatusBanner(status: .disconnected)
        StatusBanner(status: .searching)
    }
    .padding()
}
