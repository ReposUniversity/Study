//
//  DIContainer.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Data Sources
    lazy var taskDataSource: TaskDataSourceProtocol = {
        InMemoryTaskDataSource()
    }()
    
    // MARK: - Repositories
    lazy var taskRepository: TaskRepositoryProtocol = {
        TaskRepository(dataSource: taskDataSource)
    }()
    
    // MARK: - Use Cases
    lazy var getTasksUseCase: GetTasksUseCase = {
        GetTasksUseCase(repository: taskRepository)
    }()
    
    lazy var saveTaskUseCase: SaveTaskUseCase = {
        SaveTaskUseCase(repository: taskRepository)
    }()
    
    lazy var toggleTaskUseCase: ToggleTaskUseCase = {
        ToggleTaskUseCase(repository: taskRepository)
    }()
    
    // MARK: - View Models
    func makeTasksViewModel() -> TasksViewModel {
        TasksViewModel(
            getTasksUseCase: getTasksUseCase,
            saveTaskUseCase: saveTaskUseCase,
            toggleTaskUseCase: toggleTaskUseCase
        )
    }
}