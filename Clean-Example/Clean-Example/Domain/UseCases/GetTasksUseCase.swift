//
//  GetTasksUseCase.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class GetTasksUseCase {
    private let repository: TaskRepositoryProtocol

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[TaskEntity], Error> {
        repository.fetchTasks()
            .map { tasks in
                tasks.sorted { $0.createdAt > $1.createdAt }
            }
            .eraseToAnyPublisher()
    }
}