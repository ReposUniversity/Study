//
//  TaskRepository.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

protocol TaskRepositoryProtocol {
    func fetchTasks() -> AnyPublisher<[TaskEntity], Error>
    func save(_ task: TaskEntity) -> AnyPublisher<TaskEntity, Error>
    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error>
}

class TaskRepository: TaskRepositoryProtocol {
    private let dataSource: TaskDataSourceProtocol

    init(dataSource: TaskDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchTasks() -> AnyPublisher<[TaskEntity], Error> {
        dataSource.fetchTasks()
    }

    func save(_ task: TaskEntity) -> AnyPublisher<TaskEntity, Error> {
        dataSource.save(task)
    }

    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error> {
        dataSource.delete(taskId)
    }
}