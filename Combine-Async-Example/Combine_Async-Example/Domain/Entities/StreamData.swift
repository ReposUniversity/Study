//
//  StreamData.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

// MARK: - Stream Data Models

struct StreamData: Equatable {
    let items: [DataItem]
    let timestamp: Date

    init(items: [DataItem] = [], timestamp: Date = Date()) {
        self.items = items
        self.timestamp = timestamp
    }
}

struct CombinedStreamData: Equatable {
    let data: [DataItem]
    let lastUpdate: Date
    let source: DataSource

    init(data: [DataItem] = [], lastUpdate: Date = Date(), source: DataSource = .cache) {
        self.data = data
        self.lastUpdate = lastUpdate
        self.source = source
    }
}

struct DataItem: Identifiable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), content: String, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Enums

enum DataSource: String, Equatable {
    case realTime = "Real-Time"
    case api = "API"
    case cache = "Cache"
}

enum ConnectionStatus: Equatable {
    case connected
    case connecting
    case disconnected
    case error(String)
}

// MARK: - Mock Data

extension DataItem {
    static func mockItems(count: Int = 5, prefix: String = "Item") -> [DataItem] {
        (1...count).map { index in
            DataItem(
                content: "\(prefix) \(index)",
                timestamp: Date().addingTimeInterval(-Double(index * 10))
            )
        }
    }
}
