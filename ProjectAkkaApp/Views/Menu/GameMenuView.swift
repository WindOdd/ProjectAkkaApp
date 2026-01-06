//
//  GameMenuView.swift
//  ProjectAkkaApp
//
//  遊戲選單畫面
//

import SwiftUI

struct GameMenuView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel: GameMenuViewModel
    
    @State private var showSettings = false
    @State private var selectedGame: Game?
    
    init(settingsStore: SettingsStore) {
        _viewModel = StateObject(wrappedValue: GameMenuViewModel(settingsStore: settingsStore))
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("載入遊戲中...")
                        .scaleEffect(1.5)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.headline)
                        Button("重新載入") {
                            Task { await viewModel.loadGames() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.games) { game in
                                GameCard(game: game)
                                    .onTapGesture {
                                        if viewModel.selectGame(game) {
                                            selectedGame = game
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("選擇遊戲")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settingsStore: settingsStore)
            }
            .fullScreenCover(item: $selectedGame) { game in
                GameSessionView(
                    game: game,
                    settingsStore: settingsStore,
                    sessionManager: sessionManager
                )
                .onDisappear {
                    viewModel.resetNavigation()
                }
            }
            .task {
                await viewModel.loadGames()
            }
        }
    }
}

// MARK: - Game Card

struct GameCard: View {
    let game: Game
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(game.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if game.enableSttInjection {
                Label("語音優化", systemImage: "waveform")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

#Preview {
    GameMenuView(settingsStore: SettingsStore())
        .environmentObject(SessionManager())
}
