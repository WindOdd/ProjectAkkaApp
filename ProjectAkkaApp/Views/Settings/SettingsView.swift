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
        }
    }
}

#Preview {
    SettingsView(settingsStore: SettingsStore())
}

