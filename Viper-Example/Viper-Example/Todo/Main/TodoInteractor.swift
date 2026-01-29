//
//  Interactor.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

protocol TodoInteractorProtocol {
    func fetchTodo() async throws -> [TodoEntity]
}

class TodoInteractor: TodoInteractorProtocol {
    func fetchTodo() async throws -> [TodoEntity] {
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let todos = try JSONDecoder().decode([TodoEntity].self, from: data)
        return todos
    }
}

class TodoInteractorMock: TodoInteractorProtocol {
    var fetchTodoCalled = false
    var fetchTodoReturnValue: [TodoEntity] = []

    func fetchTodo() async throws -> [TodoEntity] {
        fetchTodoCalled = true
        return fetchTodoReturnValue
    }
}
