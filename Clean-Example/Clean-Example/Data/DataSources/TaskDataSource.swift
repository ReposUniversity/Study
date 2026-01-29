//
//  TaskDataSource.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

protocol TaskDataSourceProtocol {
    func fetchTasks() -> AnyPublisher<[TaskEntity], Error>
    func save(_ task: TaskEntity) -> AnyPublisher<TaskEntity, Error>
    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error>
}

class InMemoryTaskDataSource: TaskDataSourceProtocol {
    private var tasks: [TaskEntity] = []
    private let queue = DispatchQueue(label: "task.datasource", attributes: .concurrent)

    func fetchTasks() -> AnyPublisher<[TaskEntity], Error> {
        Future { promise in
            self.queue.async {
                promise(.success(self.tasks))
            }
        }
        .eraseToAnyPublisher()
    }

    func save(_ task: TaskEntity) -> AnyPublisher<TaskEntity, Error> {
        Future { promise in
            self.queue.async(flags: .barrier) {
                if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks[index] = task
                } else {
                    self.tasks.append(task)
                }
                promise(.success(task))
            }
        }
        .eraseToAnyPublisher()
    }

    func delete(_ taskId: UUID) -> AnyPublisher<Void, Error> {
        Future { promise in
            self.queue.async(flags: .barrier) {
                self.tasks.removeAll { $0.id == taskId }
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}