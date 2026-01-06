//
//  ServerDiscoveryResponse.swift
//  ProjectAkkaApp
//
//  UDP 服務發現回應
//

import Foundation

struct ServerDiscoveryResponse: Codable, Sendable {
    let ip: String
    let port: Int
    let status: String     // "ready"
}
