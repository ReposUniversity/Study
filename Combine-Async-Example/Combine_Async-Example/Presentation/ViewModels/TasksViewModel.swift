//
//  TasksViewModel.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskEntity] = []
    @Published var isLoading = false
    @Published var newTaskTitle = ""

    private let getTasksUseCase: GetTasksUseCase
    private let saveTaskUseCase: SaveTaskUseCase
    private let toggleTaskUseCase: ToggleTaskUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        getTasksUseCase: GetTasksUseCase,
        saveTaskUseCase: SaveTaskUseCase,
        toggleTaskUseCase: ToggleTaskUseCase
    ) {
        self.getTasksUseCase = getTasksUseCase
        self.saveTaskUseCase = saveTaskUseCase
        self.toggleTaskUseCase = toggleTaskUseCase
    }

    func loadTasks() {
        isLoading = true
        getTasksUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in self.isLoading = false },
                receiveValue: { tasks in self.tasks = tasks }
            )
            .store(in: &cancellables)
    }

    func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        saveTaskUseCase.execute(title: newTaskTitle)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    self.newTaskTitle = ""
                    self.loadTasks()
                }
            )
            .store(in: &cancellables)
    }

    func toggleTask(_ task: TaskEntity) {
        toggleTaskUseCase.execute(task: task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in self.loadTasks() }
            )
            .store(in: &cancellables)
    }
}