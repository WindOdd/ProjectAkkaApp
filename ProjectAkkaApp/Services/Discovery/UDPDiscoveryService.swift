//
//  UDPDiscoveryService.swift
//  ProjectAkkaApp
//
//  UDP 廣播與服務發現 (使用 BSD Socket，支援計算子網廣播地址)
//

import Foundation
import Network
import Combine
import Darwin

@MainActor
class UDPDiscoveryService: ObservableObject {
    // MARK: - Published States
    @Published var discoveredServer: ServerDiscoveryResponse?
    @Published var isSearching: Bool = false
    @Published var statusMessage: String = "準備連線..."
    @Published var currentRound: Int = 0
    @Published var errorMessage: String?

    // MARK: - Internal Properties
    private var socketFD: Int32 = -1
    private let dispatchQueue = DispatchQueue(label: "com.akka.udp.bsd", qos: .userInitiated)

    // 參數設定 (從 Constants 讀取)
    private var maxRetriesPerCycle: Int { Constants.UDPDiscovery.retryPerRound }
    private var maxCycles: Int { Constants.UDPDiscovery.maxRounds }
    private var cooldownSeconds: Double { Constants.UDPDiscovery.sleepDuration }

    // 計數器
    private var currentRetry = 0
    private var currentCycle = 0

    // 用於取消延遲任務的 WorkItem
    private var pendingTask: DispatchWorkItem?

    // MARK: - Public Methods

    func startDiscovery() {
        stopDiscovery() // 重置狀態

        print("🚀 啟動智慧 UDP 搜尋 (Random Jitter + Backoff)...")

        // 同步設定狀態 (修正競態條件)
        discoveredServer = nil
        isSearching = true  // 必須同步設定，否則接收迴圈會立即退出
        currentCycle = 0
        currentRetry = 0
        currentRound = 0
        statusMessage = "正在呼叫阿卡主機..."
        errorMessage = nil

        print("🔧 正在設定 Socket...")
        if setupSocket() {
            print("✅ Socket 設定成功，啟動接收迴圈...")
            startReceivingLoop()
            scheduleNextBroadcast(delay: 0.1)
        } else {
            print("❌ Socket 設定失敗")
            isSearching = false
            statusMessage = "Socket 初始化失敗"
            errorMessage = "無法初始化 UDP Socket"
        }
    }

    func stopDiscovery() {
        // 同步設定狀態 (修正競態條件)
        isSearching = false

        pendingTask?.cancel()
        pendingTask = nil

        if socketFD >= 0 {
            close(socketFD)
            socketFD = -1
        }

        print("🛑 UDP Discovery 已停止")
    }

    // MARK: - Logic Core

    private func scheduleNextBroadcast(delay: TimeInterval) {
        print("⏰ 排程下一次廣播 (delay: \(delay)s)")
        let task = DispatchWorkItem { [weak self] in
            self?.performBroadcastStep()
        }
        self.pendingTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    private func performBroadcastStep() {
        print("🔄 執行廣播步驟 (isSearching=\(isSearching), discoveredServer=\(discoveredServer != nil))")

        guard isSearching && discoveredServer == nil else {
            print("⏹️ 廣播已停止或已找到 Server")
            return
        }

        if currentRetry >= maxRetriesPerCycle {
            handleCycleCompletion()
            return
        }

        currentRetry += 1
        statusMessage = "搜尋中 (輪次 \(currentCycle + 1)/\(maxCycles) - 次數 \(currentRetry)/\(maxRetriesPerCycle))..."

        sendBroadcast()

        // 隨機間隔避免碰撞
        let randomInterval = Double.random(
            in: Constants.UDPDiscovery.retryIntervalMin...Constants.UDPDiscovery.retryIntervalMax
        )
        scheduleNextBroadcast(delay: randomInterval)
    }

    private func handleCycleCompletion() {
        currentCycle += 1
        currentRound = currentCycle

        if currentCycle >= maxCycles {
            print("⚠️ UDP 搜尋徹底失敗 (10輪結束)")
            Task { @MainActor in
                self.stopDiscovery()
                self.statusMessage = "找不到主機，請手動設定 IP"
                self.errorMessage = "找不到 Server，請聯繫服務人員"
            }
            return
        }

        print("⏳ 第 \(currentCycle) 輪搜尋結束，冷卻 \(Int(cooldownSeconds)) 秒...")
        statusMessage = "暫無回應，\(Int(cooldownSeconds)) 秒後重試..."
        currentRetry = 0
        scheduleNextBroadcast(delay: cooldownSeconds)
    }

    // MARK: - Low Level Socket Operations

    private func setupSocket() -> Bool {
        socketFD = socket(AF_INET, SOCK_DGRAM, 0)
        guard socketFD >= 0 else {
            print("❌ Socket 建立失敗")
            return false
        }

        var broadcastEnable: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        addr.sin_addr.s_addr = CFSwapInt32HostToBig(INADDR_ANY)

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if bindResult < 0 {
            print("❌ Socket Bind 失敗")
            return false
        }

        print("✅ UDP Socket 初始化成功")
        return true
    }

    private func sendBroadcast() {
        guard socketFD >= 0 else {
            print("❌ Socket 未就緒")
            return
        }

        // 取得真正可用的廣播位址 (避開 255.255.255.255)
        guard let broadcastIP = getWiFiBroadcastAddress() else {
            print("⚠️ 無法找到任何支援廣播的活躍網卡 (請檢查 WiFi 連線)")
            return
        }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(Constants.defaultUDPPort).bigEndian
        addr.sin_addr.s_addr = inet_addr(broadcastIP)

        guard let data = Constants.udpDiscoveryPayload.data(using: .utf8) else {
            print("❌ UDP payload 編碼失敗")
            return
        }

        data.withUnsafeBytes { ptr in
            let result = sendto(socketFD, ptr.baseAddress, data.count, 0,
                       withUnsafePointer(to: &addr) {
                           $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
                       },
                       socklen_t(MemoryLayout<sockaddr_in>.size))

            if result < 0 {
                let errorString = String(cString: strerror(errno))
                print("❌ UDP 發送失敗: \(errorString) (Error: \(errno))")
            } else {
                print("📡 發送 UDP 廣播至: \(broadcastIP)")
            }
        }
    }

    private func startReceivingLoop() {
        print("👂 開始監聽 UDP 回應...")

        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            var buffer = [UInt8](repeating: 0, count: Constants.UDPDiscovery.receiveBufferSize)

            while self.isSearching && self.socketFD >= 0 {
                let receivedBytes = recvfrom(self.socketFD, &buffer, buffer.count, 0, nil, nil)

                if receivedBytes > 0 {
                    let data = Data(bytes: buffer, count: receivedBytes)
                    print("📦 收到 \(receivedBytes) bytes")

                    // 先印出原始內容
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("📦 原始內容: \(rawString)")

                        // 跳過自己發出的廣播
                        if rawString == Constants.udpDiscoveryPayload {
                            print("⏭️ 跳過自己的廣播")
                            continue
                        }
                    }

                    // 嘗試解析 JSON
                    if let response = try? JSONDecoder().decode(ServerDiscoveryResponse.self, from: data) {
                        print("✅ 發現 Server: \(response.ip):\(response.port)")
                        Task { @MainActor in
                            self.discoveredServer = response
                            self.statusMessage = "✅ 已連線至阿卡核心"
                            self.stopDiscovery()
                        }
                        return
                    } else {
                        print("⚠️ JSON 解析失敗")
                    }
                } else if receivedBytes < 0 {
                    let errorString = String(cString: strerror(errno))
                    print("❌ recvfrom 錯誤: \(errorString)")
                }
            }

            print("👂 停止監聽 UDP")
        }
    }

    // MARK: - Network Interface Helper

    /// 智慧尋找正確的廣播位址 (計算子網廣播地址)
    private func getWiFiBroadcastAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            print("❌ getifaddrs 失敗")
            return nil
        }
        defer { freeifaddrs(ifaddr) }

        print("🔍 掃描網路介面...")

        var ptr = ifaddr
        while let currentPtr = ptr {
            let interface = currentPtr.pointee
            let name = String(cString: interface.ifa_name)

            // 1. 必須是 IPv4
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let flags = Int32(interface.ifa_flags)

                // 取得 IP 地址用於 debug
                let addr = interface.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                let ipAddr = String(cString: inet_ntoa(addr.sin_addr))

                // 2. 檢查 flags
                let isUp = (flags & IFF_UP) == IFF_UP
                let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
                let supportsBroadcast = (flags & IFF_BROADCAST) == IFF_BROADCAST

                print("  📶 \(name): IP=\(ipAddr), UP=\(isUp), Loopback=\(isLoopback), Broadcast=\(supportsBroadcast)")

                if isUp && !isLoopback && supportsBroadcast {
                    // 3. 計算子網域廣播位址 (Subnet Directed Broadcast)
                    let mask = interface.ifa_netmask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }

                    // Broadcast = (IP | ~Mask)
                    let broadcastVal = (addr.sin_addr.s_addr | (~mask.sin_addr.s_addr))

                    var broadcastAddr = sockaddr_in()
                    broadcastAddr.sin_family = sa_family_t(AF_INET)
                    broadcastAddr.sin_addr.s_addr = broadcastVal

                    let ipString = String(cString: inet_ntoa(broadcastAddr.sin_addr))

                    print("✅ 選用網卡: \(name), 廣播位址: \(ipString)")
                    return ipString
                }
            }
            ptr = interface.ifa_next
        }

        print("⚠️ 找不到合適的網路介面")
        return nil
    }
}
