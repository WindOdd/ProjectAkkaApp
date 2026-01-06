//
//  SoundPlayer.swift
//  ProjectAkkaApp
//
//  系統音效播放 - 用於延遲掩蓋 (T+2.5s)
//

import AudioToolbox

enum SoundPlayer {
    /// 播放系統 Chime 音效 (T+2.5s 短回饋)
    static func playChime() {
        AudioServicesPlaySystemSound(1007)
    }
    
    /// 播放系統提示音
    static func playNotification() {
        AudioServicesPlaySystemSound(1315)
    }
    
    /// 播放錯誤音效
    static func playError() {
        AudioServicesPlaySystemSound(1053)
    }
}
