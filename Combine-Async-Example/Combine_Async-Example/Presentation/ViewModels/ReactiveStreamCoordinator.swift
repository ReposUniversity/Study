//
//  ReactiveStreamCoordinator.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

/// Reactive stream coordinator that merges WebSocket, API, and cache data
/// Demonstrates:
/// - Combining multiple Publisher streams
/// - Auto-reconnection with exponential backoff
/// - Reconciling missed updates
/// - Priority-based data merging
@MainActor
class ReactiveStreamCoordinator: ObservableObject {

    // MARK: - Published Properties

    @Published var combinedData = CombinedStreamData()
    @Published var connectionStatus: ConnectionStatus = .disconnected

    // MARK: - Private Properties

    private let webSocketService: WebSocketServiceProtocol
    private let apiService: APIServiceProtocol
    private let cacheService: CacheServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var reconnectTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        webSocketService: WebSocketServiceProtocol,
        apiService: APIServiceProtocol,
        cacheService: CacheServiceProtocol
    ) {
        self.webSocketService = webSocketService
        self.apiService = apiService
        self.cacheService = cacheService

        setupStreamCoordination()
    }

    // MARK: - Stream Coordination Setup

    /// Combines multiple reactive streams with priority-based merging
    private func setupStreamCoordination() {
        // Combine real-time updates with API data and cache
        Publishers.CombineLatest3(
            webSocketService.liveUpdates,
            apiService.dataUpdates,
            cacheService.cachedData
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] liveData, apiData, cachedData in
            self?.combineStreams(
                live: liveData,
                api: apiData,
                cached: cachedData
            )
        }
        .store(in: &cancellables)

        // Monitor connection status
        webSocketService.connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status

                // Auto-reconnect on disconnection
                if status == .disconnected {
                    self?.scheduleReconnect()
                }
            }
            .store(in: &cancellables)

        // Handle connection restoration
        webSocketService.connectionStatus
            .filter { $0 == .connected }
            .flatMap { _ in
                // Sync missed updates when reconnected
                self.apiService.fetchMissedUpdates()
            }
            .sink { [weak self] missedUpdates in
                self?.processMissedUpdates(missedUpdates)
            }
            .store(in: &cancellables)
    }

    // MARK: - Stream Merging Logic

    /// Merge data with priority: Live > API > Cache
    private func combineStreams(
        live: StreamData,
        api: StreamData,
        cached: StreamData
    ) {
        let mergedData = mergeStreamData(
            priority: [live, api, cached]
        )

        combinedData = CombinedStreamData(
            data: mergedData,
            lastUpdate: Date(),
            source: determineDataSource(live: live, api: api, cached: cached)
        )
    }

    /// Merges stream data by ID with priority order (highest priority last)
    private func mergeStreamData(priority: [StreamData]) -> [DataItem] {
        var mergedItems: [UUID: DataItem] = [:]

        // Apply data in reverse priority order (lowest to highest)
        for streamData in priority.reversed() {
            for item in streamData.items {
                mergedItems[item.id] = item
            }
        }

        return Array(mergedItems.values)
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Determine which source provided the most recent data
    private func determineDataSource(
        live: StreamData,
        api: StreamData,
        cached: StreamData
    ) -> DataSource {
        if !live.items.isEmpty {
            return .realTime
        } else if !api.items.isEmpty {
            return .api
        } else {
            return .cache
        }
    }

    // MARK: - Reconnection Logic

    /// Schedule reconnection with exponential backoff
    private func scheduleReconnect() {
        reconnectTask?.cancel()

        reconnectTask = Task {
            var delay: TimeInterval = 1.0

            while connectionStatus == .disconnected {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                guard !Task.isCancelled else { return }

                await attemptReconnect()

                // Exponential backoff with max delay of 30 seconds
                delay = min(delay * 2, 30.0)
                print("Next reconnection attempt in \(delay)s")
            }
        }
    }

    /// Attempt to reconnect to WebSocket
    private func attemptReconnect() async {
        do {
            try await webSocketService.connect()
            print("Reconnected successfully")
        } catch {
            print("Reconnection failed: \(error)")
        }
    }

    // MARK: - Missed Updates Processing

    /// Process and reconcile missed updates after reconnection
    private func processMissedUpdates(_ updates: [DataItem]) {
        var currentItems = combinedData.data

        for update in updates {
            if let index = currentItems.firstIndex(where: { $0.id == update.id }) {
                currentItems[index] = update
            } else {
                currentItems.append(update)
            }
        }

        combinedData = CombinedStreamData(
            data: currentItems.sorted { $0.timestamp > $1.timestamp },
            lastUpdate: Date(),
            source: .api
        )

        print("Processed \(updates.count) missed updates")
    }

    // MARK: - Public API

    /// Manually refresh data from API
    func refreshData() async {
        do {
            let freshData = try await apiService.fetchLatestData().asyncThrows()

            combinedData = CombinedStreamData(
                data: freshData,
                lastUpdate: Date(),
                source: .api
            )
        } catch {
            print("Failed to refresh data: \(error)")
        }
    }

    /// Start streaming
    func startStreaming() async {
        do {
            try await webSocketService.connect()
        } catch {
            print("Failed to start streaming: \(error)")
        }
    }

    /// Stop streaming
    func stopStreaming() {
        webSocketService.disconnect()
        reconnectTask?.cancel()
    }

    // MARK: - Cleanup

    deinit {
        webSocketService.disconnect()
        reconnectTask?.cancel()
        cancellables.removeAll()
    }
}
