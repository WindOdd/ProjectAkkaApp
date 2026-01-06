//
//  GameSessionView.swift
//  ProjectAkkaApp
//
//  遊戲主畫面 - 互動對話介面
//

import SwiftUI

struct GameSessionView: View {
    let game: Game
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyManager: HistoryManager
    
    @StateObject private var viewModel: GameSessionViewModel
    
    init(game: Game, settingsStore: SettingsStore, sessionManager: SessionManager) {
        self.game = game
        
        let keywordManager = KeywordInjectionManager()
        let historyManager = HistoryManager()
        
        _viewModel = StateObject(wrappedValue: GameSessionViewModel(
            settingsStore: settingsStore,
            sessionManager: sessionManager,
            historyManager: historyManager,
            keywordManager: keywordManager
        ))
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 頂部導航欄
                headerBar
                
                // 回應顯示區
                responseArea
                    .frame(maxHeight: .infinity)
                
                // 底部控制區
                controlArea
            }
            
            // Loading 遮罩
            if viewModel.isLoading {
                LoadingOverlay(message: $viewModel.loadingMessage)
            }
        }
        .task {
            await viewModel.enterGame(game)
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            Button {
                viewModel.exitGame()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("離開")
                }
            }
            
            Spacer()
            
            Text(game.name)
                .font(.headline)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 60)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Response Area
    
    private var responseArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.responseText.isEmpty {
                    // 空狀態提示
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.5))
                        
                        Text("按住下方按鈕開始說話")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    // AI 回應
                    Text(viewModel.responseText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
                
                // 錯誤訊息
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Control Area
    
    private var controlArea: some View {
        VStack(spacing: 16) {
            // 錄音狀態指示
            if viewModel.speechService.isRecording {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                    
                    Text("錄音中...")
                        .foregroundColor(.secondary)
                    
                    if viewModel.speechService.isInWarningZone {
                        CountdownIndicator(seconds: viewModel.speechService.remainingSeconds)
                    }
                }
            }
            
            // 錄音按鈕
            RecordButton(
                isRecording: viewModel.speechService.isRecording,
                elapsedTime: viewModel.speechService.elapsedTime,
                onStart: {
                    viewModel.startRecording()
                },
                onStop: {
                    Task {
                        await viewModel.stopRecordingAndSend()
                    }
                }
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    GameSessionView(
        game: Game(id: "1", name: "卡卡頌", enableSttInjection: true),
        settingsStore: SettingsStore(),
        sessionManager: SessionManager()
    )
}
