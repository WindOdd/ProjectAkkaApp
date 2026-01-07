//
//  PermissionManager.swift
//  ProjectAkkaApp
//
//  三項權限檢查與請求
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class PermissionManager: ObservableObject {
    @Published var microphoneStatus: PermissionStatus = .unknown
    @Published var speechRecognitionStatus: PermissionStatus = .unknown
    @Published var localNetworkStatus: PermissionStatus = .unknown
    
    enum PermissionStatus {
        case unknown
        case authorized
        case denied
        case restricted
    }
    
    // MARK: - Check Current Status
    
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
        // Local Network 權限會在首次連線時觸發
    }
    
    private func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .undetermined:
            microphoneStatus = .unknown
        @unknown default:
            microphoneStatus = .unknown
        }
    }
    
    private func checkSpeechRecognitionPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionStatus = .authorized
        case .denied:
            speechRecognitionStatus = .denied
        case .restricted:
            speechRecognitionStatus = .restricted
        case .notDetermined:
            speechRecognitionStatus = .unknown
        @unknown default:
            speechRecognitionStatus = .unknown
        }
    }
    
    // MARK: - Request Permissions
    
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                // 使用 Task { @MainActor } 回到 MainActor 上下文
                Task { @MainActor in
                    self.microphoneStatus = granted ? .authorized : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                // 使用 Task { @MainActor } 回到 MainActor 上下文
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self.speechRecognitionStatus = .authorized
                        continuation.resume(returning: true)
                    default:
                        self.speechRecognitionStatus = .denied
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    /// 請求所有權限
    func requestAllPermissions() async -> Bool {
        let micGranted = await requestMicrophonePermission()
        let speechGranted = await requestSpeechRecognitionPermission()
        return micGranted && speechGranted
    }
    
    // MARK: - Computed Properties
    
    var allPermissionsGranted: Bool {
        microphoneStatus == .authorized && speechRecognitionStatus == .authorized
    }
    
    var missingPermissions: [String] {
        var missing: [String] = []
        if microphoneStatus != .authorized { missing.append("麥克風") }
        if speechRecognitionStatus != .authorized { missing.append("語音辨識") }
        return missing
    }
}
