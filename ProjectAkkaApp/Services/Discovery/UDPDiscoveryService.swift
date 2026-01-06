//
//  UDPDiscoveryService.swift
//  ProjectAkkaApp
//
//  UDP 廣播與服務發現
//

import Foundation
import Network
import Combine
class UDPDiscoveryService: ObservableObject {
    @Published var discoveredServer: ServerDiscoveryResponse?
    @Published var isSearching = false
    @Published var currentRound = 0
    @Published var errorMessage: String?
    
    private var connection: NWConnection?
    private var listener: NWListener?
    private var shouldStop = false
    
    // MARK: - Discovery
    
    /// 開始 UDP 廣播搜尋
    /// - 單一回合: 6 次，間隔 2~5 秒隨機
    /// - 休眠: 每回合結束休眠 30 秒
    /// - 上限: 最多 10 輪
    func startDiscovery() async {
        await MainActor.run {
            isSearching = true
            shouldStop = false
            discoveredServer = nil
            errorMessage = nil
            currentRound = 0
        }
        
        setupListener()
        
        for round in 1...Constants.UDPDiscovery.maxRounds {
            if shouldStop { break }
            
            await MainActor.run { currentRound = round }
            print("🔍 UDP Discovery 第 \(round) 輪開始")
            
            for attempt in 1...Constants.UDPDiscovery.retryPerRound {
                if shouldStop { break }
                
                sendBroadcast()
                print("📡 發送廣播 #\(attempt)")
                
                // 檢查是否已收到回應
                if discoveredServer != nil {
                    await MainActor.run { isSearching = false }
                    return
                }
                
                // 隨機間隔 2~5 秒
                let delay = Double.random(
                    in: Constants.UDPDiscovery.retryIntervalMin...Constants.UDPDiscovery.retryIntervalMax
                )
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            if round < Constants.UDPDiscovery.maxRounds && !shouldStop {
                // 休眠 30 秒
                print("😴 休眠 30 秒...")
                try? await Task.sleep(
                    nanoseconds: UInt64(Constants.UDPDiscovery.sleepDuration * 1_000_000_000)
                )
            }
        }
        
        await MainActor.run {
            isSearching = false
            if discoveredServer == nil {
                errorMessage = "找不到 Server，請聯繫服務人員"
            }
        }
    }
    
    func stopDiscovery() {
        shouldStop = true
        isSearching = false
        connection?.cancel()
        listener?.cancel()
        print("🛑 UDP Discovery 已停止")
    }
    
    // MARK: - Private
    
    private func sendBroadcast() {
        let host = NWEndpoint.Host("255.255.255.255")
        let port = NWEndpoint.Port(integerLiteral: UInt16(Constants.defaultPort))
        
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.start(queue: .global())
        
        let payload = Constants.udpDiscoveryPayload.data(using: .utf8)!
        connection?.send(content: payload, completion: .contentProcessed { error in
            if let error = error {
                print("❌ UDP 發送失敗: \(error)")
            }
        })
    }
    
    private func setupListener() {
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: UInt16(Constants.defaultPort)))
            
            listener?.newConnectionHandler = { [weak self] connection in
                connection.start(queue: .global())
                self?.receiveMessage(on: connection)
            }
            
            listener?.start(queue: .global())
        } catch {
            print("❌ UDP Listener 設定失敗: \(error)")
        }
    }
    
    private func receiveMessage(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, error in
            if let data = data,
               let response = try? JSONDecoder().decode(ServerDiscoveryResponse.self, from: data) {
                DispatchQueue.main.async {
                    self?.discoveredServer = response
                    self?.stopDiscovery()
                    print("✅ 發現 Server: \(response.ip):\(response.port)")
                }
            }
        }
    }
}
