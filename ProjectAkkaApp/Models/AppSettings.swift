//
//  AppSettings.swift
//  ProjectAkkaApp
//
//  使用者設定模型 - 儲存於 UserDefaults
//

import Foundation

struct AppSettings: Codable {
    var tableId: String
    var serverIP: String
    var serverPort: Int
    var ttsVoiceIdentifier: String
    var ttsSpeakingRate: Float
    
    init(
        tableId: String = "TEST100",
        serverIP: String = "",
        serverPort: Int = 37020,
        ttsVoiceIdentifier: String = "",
        ttsSpeakingRate: Float = 0.5
    ) {
        self.tableId = tableId
        self.serverIP = serverIP
        self.serverPort = serverPort
        self.ttsVoiceIdentifier = ttsVoiceIdentifier
        self.ttsSpeakingRate = ttsSpeakingRate
    }
}
