//
//  GameSessionViewModel.swift
//  ProjectAkkaApp
//
//  遊戲進行中邏輯 - 錄音、對話、狀態管理
//

import Foundation
import Combine

@MainActor
class GameSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var userQuestion = ""      // 顯示用戶問的問題
    @Published var responseText = ""
    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var errorMessage: String?
    
    // MARK: - Dependencies

    let speechService: SpeechRecognitionService
    let ttsService: TTSService

    private let settingsStore: SettingsStore
    private let sessionManager: SessionManager
    let historyManager: HistoryManager  // 公開給 View 訪問顯示對話歷史
    private let keywordManager: KeywordInjectionManager
    private var httpClient: HTTPClient?

    private var feedbackTasks: [Task<Void, Never>] = []
    private var cancellables = Set<AnyCancellable>()

    init(
        settingsStore: SettingsStore,
        sessionManager: SessionManager,
        historyManager: HistoryManager,
        keywordManager: KeywordInjectionManager
    ) {
        self.settingsStore = settingsStore
        self.sessionManager = sessionManager
        self.historyManager = historyManager
        self.keywordManager = keywordManager
        self.speechService = SpeechRecognitionService(keywordManager: keywordManager)
        self.ttsService = TTSService.shared  // ✅ 使用已預熱的 shared 實例
        self.httpClient = HTTPClient(baseURL: settingsStore.baseURL)
        
        // 🔑 轉發 speechService 的狀態變化到 ViewModel
        speechService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // 🔑 轉發 historyManager 的狀態變化到 ViewModel
        historyManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Entry Flow
    
    /// 進入遊戲時的初始化流程
    func enterGame(_ game: Game) async {
        // Step 0: 啟動 Session
        sessionManager.startSession(game: game)
        
        // Step A: 重置關鍵字
        keywordManager.reset()
        
        // Step B & C: 若需要 STT 注入，請求並注入關鍵字
        if game.enableSttInjection {
            await loadAndInjectKeywords(gameId: game.id)
        }
        
        print("🎮 遊戲初始化完成: \(game.name)")
    }
    
    private func loadAndInjectKeywords(gameId: String) async {
        do {
            let keywords = try await httpClient?.fetchKeywords(gameId: gameId) ?? []
            if !keywords.isEmpty {
                keywordManager.inject(keywords: keywords)
            }
        } catch {
            // 例外: API 失敗時降級使用標準聽寫
            print("⚠️ 關鍵字載入失敗，使用標準聽寫: \(error)")
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        // 打斷 TTS
        if ttsService.isSpeaking {
            ttsService.stop()
        }
        
        do {
            try speechService.startRecording()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecordingAndSend() async {
        speechService.stopRecording()
        
        let transcript = speechService.transcript
        
        // 過濾空字串
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ 辨識結果為空，不發送請求")
            return
        }
        
        await sendMessage(transcript)
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) async {
        guard let sessionId = sessionManager.sessionId,
              let gameId = sessionManager.currentGame?.id else {
            errorMessage = "Session 無效"
            return
        }
        
        // 顯示用戶問題
        userQuestion = text
        
        // 開始 Loading
        isLoading = true
        loadingMessage = "阿卡思考中..."
        responseText = ""
        cancelFeedbackTasks()
        
        // T+2.5s 短回饋
        let shortFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(Constants.LatencyMasking.shortFeedbackDelay * 1_000_000_000))
            if isLoading {
                SoundPlayer.playChime()
            }
        }
        feedbackTasks.append(shortFeedbackTask)
        
        // T+7.0s 長等待提示
        let longFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(Constants.LatencyMasking.longFeedbackDelay * 1_000_000_000))
            if isLoading {
                loadingMessage = "正在查詢規則，請稍候..."
            }
        }
        feedbackTasks.append(longFeedbackTask)
        
        // 建立請求
        let request = ChatRequest(
            tableId: settingsStore.settings.tableId,
            sessionId: sessionId,
            gameContext: ChatRequest.GameContext(gameId: gameId),
            userInput: text,
            history: historyManager.messages
        )
        
        do {
            let response = try await httpClient?.sendChat(request: request)
            
            // 成功處理
            cancelFeedbackTasks()
            isLoading = false
            
            if let response = response {
                responseText = response.response
                
                // 寫入 History
                historyManager.addExchange(
                    userContent: text,
                    assistantContent: response.response,
                    intent: response.intent
                )
                
                // TTS 朗讀
                ttsService.speak(
                    text: response.response,
                    voiceIdentifier: settingsStore.settings.ttsVoiceIdentifier,
                    rate: settingsStore.settings.ttsSpeakingRate
                )
            }
            
        } catch {
            // 失敗處理
            cancelFeedbackTasks()
            isLoading = false
            
            // TTS: 播報錯誤訊息
            let errorText = "抱歉，連線逾時，請稍後再試"
            ttsService.speak(
                text: errorText,
                voiceIdentifier: settingsStore.settings.ttsVoiceIdentifier,
                rate: settingsStore.settings.ttsSpeakingRate
            )
            
            errorMessage = error.localizedDescription
            
            // 不寫入 History (保持 History 乾淨)
            print("❌ 對話請求失敗，不寫入 History: \(error)")
        }
    }
    
    // MARK: - Exit Game
    
    func exitGame() {
        // 停止所有進行中的任務
        cancelFeedbackTasks()
        
        if speechService.isRecording {
            speechService.stopRecording()
        }
        
        if ttsService.isSpeaking {
            ttsService.stop()
        }
        
        // 清空關鍵字
        keywordManager.reset()
        
        // 清空 History
        historyManager.clear()
        
        // 結束 Session
        sessionManager.endSession()
        
        print("🎮 退出遊戲，資源已釋放")
    }
    
    // MARK: - Private
    
    private func cancelFeedbackTasks() {
        feedbackTasks.forEach { $0.cancel() }
        feedbackTasks.removeAll()
    }
}
