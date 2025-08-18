//
//  Presenter.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

protocol TodoPresenterProtocol {
    func loadTodos() async
    func startDetail(for todo: TodoEntity)
}

class TodoPresenter: ObservableObject, TodoPresenterProtocol {
    @Published var todos: [TodoEntity] = []
    let interactor: TodoInteractorProtocol
    let router: TodoRouterProtocol
    
    init(
        interactor: TodoInteractorProtocol,
        router: TodoRouterProtocol
    ) {
        self.interactor = interactor
        self.router = router
    }
    
    func loadTodos() async {
        let todos = try? await interactor.fetchTodo()
        
        await MainActor.run {
            self.todos = todos ?? []
        }
    }
    
    func startDetail(for todo: TodoEntity) {
        router.openDetail(for: todo)
    }
        
}

class TodoPresenterMock: TodoPresenterProtocol {
    var todos: [TodoEntity] = []
    
    func loadTodos() {
        todos = [TodoEntity(userId: 1, id: 1, title: "Test Todo", completed: false)]
    }
    
    func startDetail(for todo: TodoEntity) {
    }
}
