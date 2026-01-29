//
//  StreamServices.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

// MARK: - Service Protocols

protocol WebSocketServiceProtocol {
    var liveUpdates: AnyPublisher<StreamData, Never> { get }
    var connectionStatus: AnyPublisher<ConnectionStatus, Never> { get }

    func connect() async throws
    func disconnect()
}

protocol APIServiceProtocol {
    var dataUpdates: AnyPublisher<StreamData, Never> { get }

    func fetchLatestData() -> AnyPublisher<[DataItem], Error>
    func fetchMissedUpdates() -> AnyPublisher<[DataItem], Never>
}

protocol CacheServiceProtocol {
    var cachedData: AnyPublisher<StreamData, Never> { get }
}

// MARK: - Mock WebSocket Service

@MainActor
class MockWebSocketService: WebSocketServiceProtocol {

    private let liveUpdatesSubject = PassthroughSubject<StreamData, Never>()
    private let connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.disconnected)
    private var updateTimer: Timer?

    var liveUpdates: AnyPublisher<StreamData, Never> {
        liveUpdatesSubject.eraseToAnyPublisher()
    }

    var connectionStatus: AnyPublisher<ConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }

    func connect() async throws {
        connectionStatusSubject.send(.connecting)

        // Simulate connection delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        connectionStatusSubject.send(.connected)

        // Start sending live updates every 3 seconds
        startLiveUpdates()
    }

    func disconnect() {
        updateTimer?.invalidate()
        updateTimer = nil
        connectionStatusSubject.send(.disconnected)
    }

    private func startLiveUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  self.connectionStatusSubject.value == .connected else {
                return
            }

            let items = DataItem.mockItems(count: 2, prefix: "Live")
            let streamData = StreamData(items: items, timestamp: Date())
            self.liveUpdatesSubject.send(streamData)
        }
    }
}

// MARK: - Mock API Service

@MainActor
class MockAPIService: APIServiceProtocol {

    private let dataUpdatesSubject = PassthroughSubject<StreamData, Never>()
    private var updateTimer: Timer?

    var dataUpdates: AnyPublisher<StreamData, Never> {
        dataUpdatesSubject.eraseToAnyPublisher()
    }

    init() {
        startPeriodicUpdates()
    }

    func fetchLatestData() -> AnyPublisher<[DataItem], Error> {
        Future { promise in
            Task {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                let items = DataItem.mockItems(count: 5, prefix: "API")
                promise(.success(items))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchMissedUpdates() -> AnyPublisher<[DataItem], Never> {
        Future { promise in
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                let items = DataItem.mockItems(count: 3, prefix: "Missed")
                promise(.success(items))
            }
        }
        .eraseToAnyPublisher()
    }

    private func startPeriodicUpdates() {
        // Send API updates every 5 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            let items = DataItem.mockItems(count: 3, prefix: "API Update")
            let streamData = StreamData(items: items, timestamp: Date())
            self?.dataUpdatesSubject.send(streamData)
        }
    }

    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Mock Cache Service

class MockCacheService: CacheServiceProtocol {

    private let cachedDataSubject = CurrentValueSubject<StreamData, Never>(
        StreamData(items: DataItem.mockItems(count: 3, prefix: "Cached"))
    )

    var cachedData: AnyPublisher<StreamData, Never> {
        cachedDataSubject.eraseToAnyPublisher()
    }
}
