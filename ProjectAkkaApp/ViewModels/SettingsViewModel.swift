//
//  SettingsViewModel.swift
//  ProjectAkkaApp
//
//  設定頁邏輯 - 連線測試、儲存設定
//

import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var tableId: String = ""
    @Published var serverIP: String = ""
    @Published var serverPort: String = ""
    
    @Published var isTestingConnection = false
    @Published var connectionTestResult: ConnectionResult?
    
    private let settingsStore: SettingsStore
    private var httpClient: HTTPClient?
    
    enum ConnectionResult: Equatable {
        case success
        case failure(String)
        
        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }
    }
    
    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        loadSettings()
    }
    
    // MARK: - Load / Save
    
    func loadSettings() {
        tableId = settingsStore.settings.tableId
        serverIP = settingsStore.settings.serverIP
        serverPort = String(settingsStore.settings.serverPort)
    }
    
    func saveSettings() {
        settingsStore.settings.tableId = tableId
        settingsStore.settings.serverIP = serverIP
        settingsStore.settings.serverPort = Int(serverPort) ?? Constants.defaultHTTPPort
    }
    
    func resetSettings() {
        settingsStore.reset()
        loadSettings()
    }
    
    // MARK: - Connection Test
    
    func testConnection() async {
        guard validateInputs() else { return }
        
        saveSettings()
        
        isTestingConnection = true
        connectionTestResult = nil
        
        let baseURL = "http://\(serverIP):\(serverPort)"
        httpClient = HTTPClient(baseURL: baseURL)
        
        do {
            _ = try await httpClient?.testConnection()
            connectionTestResult = .success
        } catch {
            connectionTestResult = .failure(error.localizedDescription)
        }
        
        isTestingConnection = false
    }
    
    // MARK: - Validation
    
    private func validateInputs() -> Bool {
        // 簡單的 IPv4 驗證
        let ipPattern = #"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"#
        let ipPredicate = NSPredicate(format: "SELF MATCHES %@", ipPattern)
        
        guard ipPredicate.evaluate(with: serverIP) else {
            connectionTestResult = .failure("請輸入有效的 IP 位址")
            return false
        }
        
        guard let port = Int(serverPort), port > 0 && port <= 65535 else {
            connectionTestResult = .failure("請輸入有效的埠號 (1-65535)")
            return false
        }
        
        return true
    }
}
