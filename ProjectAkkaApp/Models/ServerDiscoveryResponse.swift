//
//  ServerDiscoveryResponse.swift
//  ProjectAkkaApp
//
//  UDP 服務發現回應
//

import Foundation

struct ServerDiscoveryResponse: Codable, @unchecked Sendable {
    let ip: String
    let port: Int
    let status: String?     // "ready" (可選，Server 可能不回傳)
}
