//
//  SettingsViewModel.swift
//  ProjectAkkaApp
//
//  設定頁邏輯 - 連線測試、儲存設定、UDP Discovery
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
    
    // UDP Discovery
    @Published var isDiscovering = false
    @Published var discoveryStatus: String = ""
    
    private let settingsStore: SettingsStore
    private var httpClient: HTTPClient?
    private let udpDiscoveryService = UDPDiscoveryService()
    private var cancellables = Set<AnyCancellable>()
    
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
        setupDiscoveryObservers()
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
        settingsStore.save()
    }
    
    func resetSettings() {
        settingsStore.reset()
        loadSettings()
    }
    
    // MARK: - UDP Discovery
    
    private func setupDiscoveryObservers() {
        // 監聽發現的 Server
        udpDiscoveryService.$discoveredServer
            .compactMap { $0 }
            .sink { [weak self] response in
                self?.serverIP = response.ip
                self?.serverPort = String(response.port)
                self?.discoveryStatus = "✅ 找到主機: \(response.ip)"
                self?.saveSettings()
            }
            .store(in: &cancellables)

        // 監聽搜尋狀態
        udpDiscoveryService.$isSearching
            .assign(to: &$isDiscovering)

        // 監聯狀態訊息
        udpDiscoveryService.$statusMessage
            .assign(to: &$discoveryStatus)
    }
    
    /// 檢查是否應該自動開始 UDP Discovery
    func checkAutoDiscovery() {
        if serverIP.isEmpty {
            print("🔍 IP 為空，自動開始 UDP Discovery...")
            startDiscovery()
        }
    }
    
    /// 手動開始 UDP Discovery
    func startDiscovery() {
        udpDiscoveryService.startDiscovery()
    }
    
    /// 停止 UDP Discovery
    func stopDiscovery() {
        udpDiscoveryService.stopDiscovery()
    }
    
    // MARK: - Connection Test
    
    func testConnection() async {
        guard validateInputs() else { return }
        
        // 手動測試連線時，停止 UDP Discovery
        stopDiscovery()
        
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
