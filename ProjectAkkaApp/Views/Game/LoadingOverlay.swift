//
//  LoadingOverlay.swift
//  ProjectAkkaApp
//
//  「阿卡思考中...」遮罩
//

import SwiftUI

struct LoadingOverlay: View {
    @Binding var message: String
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Loading 卡片
            VStack(spacing: 20) {
                // 動畫圖示
                LoadingAnimation()
                    .frame(width: 80, height: 80)
                
                // 訊息文字
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .transition(.opacity)
    }
}

// MARK: - Loading Animation

struct LoadingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 6)
            
            // 旋轉弧線
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        LoadingOverlay(message: .constant("阿卡思考中..."))
    }
}

#Preview("Long Message") {
    ZStack {
        Color.gray
        LoadingOverlay(message: .constant("正在查詢規則，請稍候..."))
    }
}
