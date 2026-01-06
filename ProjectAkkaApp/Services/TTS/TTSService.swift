//
//  TTSService.swift
//  ProjectAkkaApp
//
//  AVSpeechSynthesizer 語音朗讀服務
//

import Foundation
import AVFoundation
import Combine

@MainActor
class TTSService: NSObject, ObservableObject {
    /// 共享實例 (保持預熱狀態)
    static let shared = TTSService()

    @Published var isSpeaking = false
    @Published var isWarmedUp = false

    private var synthesizer: AVSpeechSynthesizer?
    private var warmUpContinuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        // 預先建立 synthesizer
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
    }

    // MARK: - Pre-warm (消除首次延遲)

    /// 預熱 TTS 引擎 - 播放「準備就緒」歡迎語（非阻塞）
    func preWarm() async {
        guard !isWarmedUp else { return }
        isWarmedUp = true

        print("🔊 TTS 預熱開始 - 播放啟動語音...")

        // 使用 continuation 等待播放完成
        await withCheckedContinuation { continuation in
            warmUpContinuation = continuation

            // 播放有聲的歡迎語來預熱 TTS 引擎
            let warmUpUtterance = AVSpeechUtterance(string: "準備就緒")
            warmUpUtterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
            warmUpUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
            warmUpUtterance.volume = 1.0  // 正常音量

            isSpeaking = true
            synthesizer?.speak(warmUpUtterance)
        }
    }
    
    // MARK: - Speech Control
    
    /// 朗讀文字
    /// - Parameters:
    ///   - text: 要朗讀的文字
    ///   - voiceIdentifier: 語音識別碼 (可選)
    ///   - rate: 語速 (0.0 ~ 1.0)
    func speak(text: String, voiceIdentifier: String = "", rate: Float = 0.5) {
        // 確保 synthesizer 存在
        if synthesizer == nil {
            synthesizer = AVSpeechSynthesizer()
            synthesizer?.delegate = self
        }
        
        // 停止目前的朗讀
        if isSpeaking {
            synthesizer?.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 設定語音
        if !voiceIdentifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            // 降級策略：使用系統預設中文語音
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        }
        
        // 設定語速
        // AVSpeechUtterance.rate 範圍：0.0 (最慢) ~ 1.0 (最快)
        // 正常語速約為 0.5，我們的 rate 輸入也是 0.0 ~ 1.0
        // 將輸入映射到 0.1 ~ 0.6 的範圍 (避免太快或太慢)
        let minRate: Float = 0.1
        let maxRate: Float = 0.6
        utterance.rate = minRate + (rate * (maxRate - minRate))
        
        isSpeaking = true
        synthesizer?.speak(utterance)
        
        print("🔊 TTS 開始朗讀: \(text.prefix(30))...")
    }
    
    /// 立即停止朗讀 (按下錄音鈕時呼叫)
    func stop() {
        synthesizer?.stopSpeaking(at: .immediate)
        isSpeaking = false
        print("🔊 TTS 已停止")
    }
    
    // MARK: - Voice List
    
    /// 取得系統可用的繁體中文語音列表
    static func availableChineseVoices() -> [VoiceInfo] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("zh-TW") }
            .map { VoiceInfo(identifier: $0.identifier, name: $0.name) }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            print("🔊 TTS 朗讀完成")

            // Resume continuation if this was the warm-up
            if let continuation = self.warmUpContinuation {
                self.warmUpContinuation = nil
                continuation.resume()
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false

            // Resume continuation if cancelled during warm-up
            if let continuation = self.warmUpContinuation {
                self.warmUpContinuation = nil
                continuation.resume()
            }
        }
    }
}

// MARK: - Voice Info

struct VoiceInfo: Identifiable {
    let id: String
    let identifier: String
    let name: String
    
    init(identifier: String, name: String) {
        self.id = identifier
        self.identifier = identifier
        self.name = name
    }
}
