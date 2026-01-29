//
//  SaveTaskUseCase.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class SaveTaskUseCase {
    private let repository: TaskRepositoryProtocol

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    func execute(title: String) -> AnyPublisher<TaskEntity, Error> {
        let task = TaskEntity(
            id: UUID(),
            title: title,
            isCompleted: false,
            createdAt: Date()
        )
        return repository.save(task)
    }
}