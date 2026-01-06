//
//  ContentView.swift
//  ProjectAkkaApp
//
//  主入口視圖 - 導航控制
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var permissionManager: PermissionManager
    
    @State private var hasInitialized = false
    @State private var showPermissionAlert = false
    @State private var isSystemReady = false
    @State private var loadingMessage = "系統啟動中..."
    
    var body: some View {
        ZStack {
            // 主畫面
            Group {
                if !settingsStore.hasValidServer {
                    // 首次啟動或無有效連線 -> 設定頁面
                    SettingsView(settingsStore: settingsStore) {
                        // 連線成功後不需額外處理
                    }
                } else {
                    // 有有效連線 -> 遊戲選單
                    GameMenuView(settingsStore: settingsStore)
                }
            }
            .disabled(!isSystemReady)  // 未就緒時禁用互動
            .blur(radius: isSystemReady ? 0 : 3)  // 模糊效果
            
            // 啟動 Loading 遮罩
            if !isSystemReady {
                StartupLoadingView(message: loadingMessage)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSystemReady)
        .task {
            guard !hasInitialized else { return }
            hasInitialized = true
            
            // 1. 檢查權限
            loadingMessage = "檢查權限中..."
            print("🚀 App 啟動：檢查權限...")
            permissionManager.checkAllPermissions()
            
            if !permissionManager.allPermissionsGranted {
                _ = await permissionManager.requestAllPermissions()
            }
            
            // 2. 預熱 TTS
            loadingMessage = "語音引擎準備中..."
            print("🚀 App 啟動：預熱 TTS...")
            TTSService.shared.preWarm()
            
            // 3. 等待 TTS 完成
            while TTSService.shared.isSpeaking {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            // 4. 系統就緒
            print("🚀 App 啟動完成！")
            isSystemReady = true
            
            // 5. 顯示權限缺失警告
            if !permissionManager.allPermissionsGranted {
                showPermissionAlert = true
            }
        }
        .alert("權限不足", isPresented: $showPermissionAlert) {
            Button("前往設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("稍後再說", role: .cancel) { }
        } message: {
            Text("請在設定中允許麥克風和語音辨識權限，以使用語音功能。")
        }
    }
}

// MARK: - Startup Loading View

struct StartupLoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo 或名稱
                Text("阿卡")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                // Loading 動畫
                ProgressView()
                    .scaleEffect(1.5)
                
                // 狀態訊息
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
        .environmentObject(SessionManager())
        .environmentObject(HistoryManager())
        .environmentObject(PermissionManager())
}
