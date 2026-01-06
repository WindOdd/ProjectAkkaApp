//
//  Constants.swift
//  ProjectAkkaApp
//
//  全域常數定義
//

import Foundation

enum Constants {
    // MARK: - Network
    static let defaultPort: Int = 37020
    static let udpDiscoveryPayload = "DISCOVER_AKKA_SERVER"
    
    // MARK: - Timeout (seconds)
    enum Timeout {
        /// 測試連線 - 連線逾時
        static let connectionTestConnect: TimeInterval = 3
        /// 測試連線 - 讀取逾時
        static let connectionTestRead: TimeInterval = 5
        /// 對話請求 - 連線逾時
        static let chatRequestConnect: TimeInterval = 5
        /// 對話請求 - 讀取逾時 (等待 RAG)
        static let chatRequestRead: TimeInterval = 30
    }
    
    // MARK: - Recording
    enum Recording {
        /// 錄音總時長上限
        static let maxDuration: TimeInterval = 40
        /// 警示閾值 (開始倒數)
        static let warningThreshold: TimeInterval = 30
    }
    
    // MARK: - UDP Discovery
    enum UDPDiscovery {
        /// 每輪重試次數
        static let retryPerRound = 6
        /// 重試間隔最小值 (秒)
        static let retryIntervalMin: TimeInterval = 2
        /// 重試間隔最大值 (秒)
        static let retryIntervalMax: TimeInterval = 5
        /// 每輪結束休眠時間
        static let sleepDuration: TimeInterval = 30
        /// 最大輪數
        static let maxRounds = 10
    }
    
    // MARK: - History
    enum History {
        /// 對話歷史上限 (輪數，每輪 = user + assistant)
        static let maxRounds = 8
    }
    
    // MARK: - Latency Masking
    enum LatencyMasking {
        /// 短回饋延遲 (播放音效)
        static let shortFeedbackDelay: TimeInterval = 2.5
        /// 長等待提示延遲 (變更文字)
        static let longFeedbackDelay: TimeInterval = 7.0
    }
    
    // MARK: - TTS
    enum TTS {
        /// 語速範圍最小值
        static let minSpeakingRate: Float = 0.0
        /// 語速範圍最大值
        static let maxSpeakingRate: Float = 1.0
        /// 預設語速
        static let defaultSpeakingRate: Float = 0.5
    }
}
