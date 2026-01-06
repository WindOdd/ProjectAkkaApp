//
//  View+Loading.swift
//  ProjectAkkaApp
//
//  View Loading Extension
//

import SwiftUI

extension View {
    /// 條件式 Loading 遮罩
    @ViewBuilder
    func loading(isLoading: Bool, message: String = "載入中...") -> some View {
        ZStack {
            self
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }
    
    /// 禁用互動
    func disabled(while isLoading: Bool) -> some View {
        self
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1)
    }
}
