//
//  NetworkError.swift
//  ProjectAkkaApp
//
//  網路錯誤類型定義
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case connectionTimeout
    case readTimeout
    case serverError(statusCode: Int)
    case decodingError(Error)
    case noData
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的網址"
        case .connectionTimeout:
            return "連線逾時"
        case .readTimeout:
            return "讀取逾時"
        case .serverError(let code):
            return "伺服器錯誤 (\(code))"
        case .decodingError:
            return "資料解析錯誤"
        case .noData:
            return "無回應資料"
        case .unknown(let error):
            return "未知錯誤: \(error.localizedDescription)"
        }
    }
    
    var isTimeout: Bool {
        switch self {
        case .connectionTimeout, .readTimeout:
            return true
        default:
            return false
        }
    }
}
