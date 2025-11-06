//
//  TaskEntity.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

struct TaskEntity {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let createdAt: Date

    func toggle() -> TaskEntity {
        TaskEntity(
            id: id,
            title: title,
            isCompleted: !isCompleted,
            createdAt: createdAt
        )
    }
}