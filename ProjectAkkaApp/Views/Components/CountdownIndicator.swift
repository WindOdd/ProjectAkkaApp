//
//  CountdownIndicator.swift
//  ProjectAkkaApp
//
//  30s ~ 40s 倒數顯示元件
//

import SwiftUI

struct CountdownIndicator: View {
    let seconds: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .foregroundColor(.red)
            
            Text("\(seconds)秒")
                .foregroundColor(.red)
                .fontWeight(.bold)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.15))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: seconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        CountdownIndicator(seconds: 10)
        CountdownIndicator(seconds: 5)
        CountdownIndicator(seconds: 1)
    }
    .padding()
}
