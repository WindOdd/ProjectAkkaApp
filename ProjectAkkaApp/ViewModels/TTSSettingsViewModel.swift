//
//  TTSSettingsViewModel.swift
//  ProjectAkkaApp
//
//  TTS 聲音選擇與語速設定
//

import Foundation
import AVFoundation
import Combine
@MainActor
class TTSSettingsViewModel: ObservableObject {
    @Published var availableVoices: [VoiceInfo] = []
    @Published var selectedVoiceId: String = ""
    @Published var speakingRate: Float = 0.5
    @Published var isPlaying = false
    
    private let settingsStore: SettingsStore
    private let ttsService = TTSService.shared
    
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        loadSettings()
        loadVoices()
    }
    
    // MARK: - Load / Save
    
    func loadSettings() {
        selectedVoiceId = settingsStore.settings.ttsVoiceIdentifier
        speakingRate = settingsStore.settings.ttsSpeakingRate
    }
    
    func saveSettings() {
        settingsStore.settings.ttsVoiceIdentifier = selectedVoiceId
        settingsStore.settings.ttsSpeakingRate = speakingRate
    }
    
    // MARK: - Voice List
    
    func loadVoices() {
        availableVoices = TTSService.availableChineseVoices()
        
        // 若尚未選擇，預設使用第一個
        if selectedVoiceId.isEmpty, let first = availableVoices.first {
            selectedVoiceId = first.identifier
        }
        
        print("🔊 載入 \(availableVoices.count) 個中文語音")
    }
    
    // MARK: - Preview
    
    func previewVoice() {
        if isPlaying {
            ttsService.stop()
            isPlaying = false
        } else {
            isPlaying = true
            ttsService.speak(
                text: "您好，我是阿卡，您的桌遊助手。",
                voiceIdentifier: selectedVoiceId,
                rate: speakingRate
            )
            
            // 監聽完成
            Task {
                while ttsService.isSpeaking {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                isPlaying = false
            }
        }
    }
    
    func stopPreview() {
        ttsService.stop()
        isPlaying = false
    }
}
