//
//  RecordButton.swift
//  ProjectAkkaApp
//
//  錄音按鈕 - 含倒數、顏色變化
//

import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let elapsedTime: TimeInterval
    
    var onStart: () -> Void
    var onStop: () -> Void
    
    private let buttonSize: CGFloat = 100
    
    var body: some View {
        Button {
            if isRecording {
                onStop()
            } else {
                onStart()
            }
        } label: {
            ZStack {
                // 外圈
                Circle()
                    .stroke(buttonColor.opacity(0.3), lineWidth: 4)
                    .frame(width: buttonSize + 20, height: buttonSize + 20)
                
                // 主按鈕
                Circle()
                    .fill(buttonColor)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: buttonColor.opacity(0.5), radius: 10)
                
                // 內容
                if isInWarningZone && isRecording {
                    // 倒數數字 (30s ~ 40s)
                    Text("\(remainingSeconds)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    // 麥克風圖示
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .animation(.easeInOut(duration: 0.2), value: isInWarningZone)
    }
    
    // MARK: - Computed Properties
    
    private var isInWarningZone: Bool {
        elapsedTime >= Constants.Recording.warningThreshold
    }
    
    private var remainingSeconds: Int {
        max(0, Int(Constants.Recording.maxDuration - elapsedTime))
    }
    
    private var buttonColor: Color {
        if isInWarningZone && isRecording {
            return .red  // 警示狀態
        } else if isRecording {
            return .blue  // 錄音中
        } else {
            return .green  // 待機
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // 待機狀態
        RecordButton(
            isRecording: false,
            elapsedTime: 0,
            onStart: {},
            onStop: {}
        )
        
        // 錄音中
        RecordButton(
            isRecording: true,
            elapsedTime: 15,
            onStart: {},
            onStop: {}
        )
        
        // 警示狀態
        RecordButton(
            isRecording: true,
            elapsedTime: 35,
            onStart: {},
            onStop: {}
        )
    }
    .padding()
}
