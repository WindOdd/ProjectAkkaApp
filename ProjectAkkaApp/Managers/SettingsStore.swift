//
//  SettingsStore.swift
//  ProjectAkkaApp
//
//  UserDefaults 存取封裝 - 單一資料源
//

import Foundation
import Combine

@MainActor
class SettingsStore: ObservableObject {
    @Published var settings: AppSettings
    
    private let key = "com.projectakka.settings"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }
    
    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func reset() {
        settings = AppSettings()
        save()
    }
    
    // MARK: - Computed Properties
    
    var baseURL: String {
        guard !settings.serverIP.isEmpty else { return "" }
        return "http://\(settings.serverIP):\(settings.serverPort)"
    }
    
    var hasValidServer: Bool {
        !settings.serverIP.isEmpty
    }
}
