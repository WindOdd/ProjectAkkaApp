//
//  KeywordsResponse.swift
//  ProjectAkkaApp
//
//  GET /api/keywords/{game_id} 回應
//

import Foundation

struct KeywordsResponse: Codable {
    let id: String
    let keywords: [String]  // ["卡卡頌", "米寶", "板塊"]
}
