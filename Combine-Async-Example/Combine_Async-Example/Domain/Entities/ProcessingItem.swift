//
//  ProcessingItem.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

// MARK: - Processing Models

struct ProcessingItem: Identifiable {
    let id: UUID
    let name: String
    let data: Data

    init(id: UUID = UUID(), name: String, data: Data = Data()) {
        self.id = id
        self.name = name
        self.data = data
    }
}

struct ProcessingResult: Identifiable {
    let id = UUID()
    let itemId: UUID
    let status: ProcessingStatus
    let data: String
    let processingTime: TimeInterval
}

struct ProcessingUpdate {
    let step: Int
    let message: String
    let timestamp: Date
}

enum ProcessingStatus {
    case pending
    case processing
    case completed
    case failed
}

// MARK: - Mock Data

extension ProcessingItem {
    static func mockItems(count: Int = 10) -> [ProcessingItem] {
        (1...count).map { i in
            ProcessingItem(
                name: "Item \(i)",
                data: Data(repeating: UInt8(i), count: 100)
            )
        }
    }
}
