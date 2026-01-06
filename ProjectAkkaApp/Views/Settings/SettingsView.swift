//
//  SettingsView.swift
//  ProjectAkkaApp
//
//  設定主頁面
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    
    var onConnectionSuccess: (() -> Void)?
    
    init(settingsStore: SettingsStore, onConnectionSuccess: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(settingsStore: settingsStore))
        self.onConnectionSuccess = onConnectionSuccess
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 連線設定區塊
                Section("連線設定") {
                    ConnectionSettingsView(viewModel: viewModel)
                }
                
                // TTS 設定區塊
                Section("語音朗讀設定") {
                    NavigationLink {
                        TTSSettingsView(settingsStore: settingsStore)
                    } label: {
                        Label("語音設定", systemImage: "speaker.wave.3")
                    }
                }
                
                // 重置設定區塊
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置所有設定")
                        }
                        .frame(maxWidth: .infinity)
                    }
                } footer: {
                    Text("將所有設定恢復為預設值（桌號、伺服器 IP、埠號 8000、語音設定）")
                        .font(.caption)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.connectionTestResult) { _ in
                if case .success = viewModel.connectionTestResult {
                    onConnectionSuccess?()
                }
            }
            .alert("確認重置", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    viewModel.resetSettings()
                }
            } message: {
                Text("所有設定將恢復為預設值，確定要繼續嗎？")
            }
        }
    }
}

#Preview {
    SettingsView(settingsStore: SettingsStore())
}

