//
//  ConnectionSettingsView.swift
//  ProjectAkkaApp
//
//  連線設定子頁面
//

import SwiftUI

struct ConnectionSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Group {
            // 桌號
            HStack {
                Label("桌號", systemImage: "tablecells")
                Spacer()
                TextField("TEST100", text: $viewModel.tableId)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
            }
            
            // 伺服器 IP
            HStack {
                Label("伺服器 IP", systemImage: "network")
                Spacer()
                TextField("192.168.1.100", text: $viewModel.serverIP)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 180)
            }
            
            // 埠號
            HStack {
                Label("埠號", systemImage: "number")
                Spacer()
                TextField("37020", text: $viewModel.serverPort)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
            }
            
            // 測試連線按鈕
            Button {
                Task {
                    await viewModel.testConnection()
                }
            } label: {
                HStack {
                    if viewModel.isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("測試中...")
                    } else {
                        Image(systemName: "wifi")
                        Text("測試連線")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isTestingConnection)
            
            // 連線結果
            if let result = viewModel.connectionTestResult {
                HStack {
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isSuccess ? .green : .red)
                    
                    switch result {
                    case .success:
                        Text("連線成功！")
                            .foregroundColor(.green)
                    case .failure(let message):
                        Text(message)
                            .foregroundColor(.red)
                    }
                }
                .font(.callout)
            }
        }
    }
}

#Preview {
    Form {
        Section("連線設定") {
            ConnectionSettingsView(viewModel: SettingsViewModel(settingsStore: SettingsStore()))
        }
    }
}
