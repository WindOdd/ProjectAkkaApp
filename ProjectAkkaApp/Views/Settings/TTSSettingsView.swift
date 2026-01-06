//
//  TTSSettingsView.swift
//  ProjectAkkaApp
//
//  TTS 語音設定頁面
//

import SwiftUI

struct TTSSettingsView: View {
    @StateObject private var viewModel: TTSSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(settingsStore: SettingsStore) {
        _viewModel = StateObject(wrappedValue: TTSSettingsViewModel(settingsStore: settingsStore))
    }
    
    var body: some View {
        Form {
            // 語音選擇
            Section("語音選擇") {
                Picker("選擇語音", selection: $viewModel.selectedVoiceId) {
                    ForEach(viewModel.availableVoices) { voice in
                        Text(voice.name)
                            .tag(voice.identifier)
                    }
                }
                .pickerStyle(.inline)
                
                // 試聽按鈕
                Button {
                    viewModel.previewVoice()
                } label: {
                    HStack {
                        Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        Text(viewModel.isPlaying ? "停止" : "試聽")
                    }
                }
            }
            
            // 語速調整
            Section("語速調整") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("語速")
                        Spacer()
                        Text(String(format: "%.2f", viewModel.speakingRate))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $viewModel.speakingRate,
                        in: Constants.TTS.minSpeakingRate...Constants.TTS.maxSpeakingRate,
                        step: 0.05
                    ) {
                        Text("語速")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise")
                    } maximumValueLabel: {
                        Image(systemName: "hare")
                    }
                }
            }
        }
        .navigationTitle("語音設定")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stopPreview()
            viewModel.saveSettings()
        }
    }
}

#Preview {
    NavigationStack {
        TTSSettingsView(settingsStore: SettingsStore())
    }
}
