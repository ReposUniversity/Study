//
//  ToggleTaskUseCase.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class ToggleTaskUseCase {
    private let repository: TaskRepositoryProtocol

    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }

    func execute(task: TaskEntity) -> AnyPublisher<TaskEntity, Error> {
        let toggledTask = task.toggle()
        return repository.save(toggledTask)
    }
}