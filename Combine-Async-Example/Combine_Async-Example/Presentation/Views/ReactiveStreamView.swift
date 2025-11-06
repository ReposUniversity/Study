//
//  ReactiveStreamView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

/// Demonstrates reactive stream coordination
/// - Merges WebSocket, API, and cache streams
/// - Auto-reconnection with exponential backoff
/// - Reconciles missed updates
struct ReactiveStreamView: View {

    @StateObject private var coordinator = ReactiveStreamCoordinator(
        webSocketService: MockWebSocketService(),
        apiService: MockAPIService(),
        cacheService: MockCacheService()
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection status banner
                connectionStatusBanner

                // Data list
                List(coordinator.combinedData.data, id: \.id) { item in
                    dataItemRow(item)
                }
                .overlay {
                    if coordinator.combinedData.data.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "tray",
                            description: Text("Start streaming to see live data")
                        )
                    }
                }
            }
            .navigationTitle("Reactive Streams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    streamControlButton
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await coordinator.refreshData()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var connectionStatusBanner: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)

            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            Text(coordinator.combinedData.source.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)

            Text(timeAgoString(from: coordinator.combinedData.lastUpdate))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(statusBackgroundColor)
    }

    private var streamControlButton: some View {
        Button {
            Task {
                if coordinator.connectionStatus == .connected {
                    coordinator.stopStreaming()
                } else {
                    await coordinator.startStreaming()
                }
            }
        } label: {
            Label(
                coordinator.connectionStatus == .connected ? "Stop" : "Start",
                systemImage: coordinator.connectionStatus == .connected ? "stop.fill" : "play.fill"
            )
        }
    }

    private func dataItemRow(_ item: DataItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.content)
                .font(.headline)

            Text(timeAgoString(from: item.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch coordinator.connectionStatus {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .red
        case .error: return .red
        }
    }

    private var statusText: String {
        switch coordinator.connectionStatus {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let message): return "Error: \(message)"
        }
    }

    private var statusBackgroundColor: Color {
        switch coordinator.connectionStatus {
        case .connected: return Color.green.opacity(0.1)
        case .connecting: return Color.orange.opacity(0.1)
        case .disconnected: return Color.red.opacity(0.1)
        case .error: return Color.red.opacity(0.1)
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Preview

#Preview {
    ReactiveStreamView()
}
