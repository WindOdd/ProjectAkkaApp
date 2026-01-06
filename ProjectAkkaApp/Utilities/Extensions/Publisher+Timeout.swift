//
//  Publisher+Timeout.swift
//  ProjectAkkaApp
//
//  Combine Publisher Timeout Extension
//

import Foundation
import Combine

extension Publisher {
    /// 設定自訂超時時間
    func timeout(
        seconds: TimeInterval,
        scheduler: DispatchQueue = .main,
        customError: Failure? = nil
    ) -> AnyPublisher<Output, Failure> where Failure == Error {
        self
            .timeout(.seconds(seconds), scheduler: scheduler)
            .eraseToAnyPublisher()
    }
}
