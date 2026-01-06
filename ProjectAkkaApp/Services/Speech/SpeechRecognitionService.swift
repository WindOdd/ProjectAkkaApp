//
//  SpeechRecognitionService.swift
//  ProjectAkkaApp
//
//  Apple SFSpeechRecognizer 語音辨識服務
//

import Foundation
import Speech
import AVFoundation
import Combine
class SpeechRecognitionService: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var errorMessage: String?
    
    private let recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var timer: Timer?
    
    private let keywordManager: KeywordInjectionManager
    
    init(keywordManager: KeywordInjectionManager) {
        self.keywordManager = keywordManager
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    }
    
    // MARK: - Recording Control
    
    func startRecording() throws {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }
        
        // 重置狀態
        transcript = ""
        elapsedTime = 0
        errorMessage = nil
        
        // 設定 Audio Session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 建立 recognition request
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            throw SpeechError.requestCreationFailed
        }
        
        request.shouldReportPartialResults = true
        
        // 注入關鍵字
        if !keywordManager.isEmpty {
            request.contextualStrings = keywordManager.keywords
            print("🎤 已注入 \(keywordManager.count) 個關鍵字")
        }
        
        // 設定音訊輸入
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        startTimer()
        
        // 開始辨識
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
            }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.stopRecording()
            }
        }
        
        print("🎤 開始錄音")
    }
    
    func stopRecording() {
        stopTimer()
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        request = nil
        recognitionTask = nil
        
        isRecording = false
        
        // 重設 Audio Session (為 TTS 準備)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Audio Session 重設失敗: \(error)")
        }
        
        print("🎤 停止錄音，辨識結果: \(transcript)")
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.elapsedTime += 1
            
            // 40 秒強制結束
            if self.elapsedTime >= Constants.Recording.maxDuration {
                self.stopRecording()
                print("⏱️ 達到 40 秒上限，自動停止錄音")
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Computed Properties
    
    var isInWarningZone: Bool {
        elapsedTime >= Constants.Recording.warningThreshold
    }
    
    var remainingSeconds: Int {
        max(0, Int(Constants.Recording.maxDuration - elapsedTime))
    }
}

// MARK: - Errors

enum SpeechError: Error, LocalizedError {
    case recognizerNotAvailable
    case requestCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "語音辨識服務不可用"
        case .requestCreationFailed:
            return "無法建立語音辨識請求"
        }
    }
}
