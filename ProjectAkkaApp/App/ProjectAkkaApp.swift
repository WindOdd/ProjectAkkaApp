//
//  ProjectAkkaApp.swift
//  ProjectAkkaApp
//
//  Project Akka - iPad 桌遊語音助手
//

import SwiftUI

@main
struct ProjectAkkaApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var permissionManager = PermissionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(sessionManager)
                .environmentObject(historyManager)
                .environmentObject(permissionManager)
        }
    }
}
