//
//  AppDelegate.swift
//  ProjectAkkaApp
//
//  應用程式生命週期管理
//

import UIKit
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Audio Session 會在 TTS/STT 使用時再配置，避免與鍵盤衝突
        print("✅ App 啟動")
        return true
    }
}
