//
//  TodoModule.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

enum TodoModuleFactory: Hashable {
    case home
    case detail(todo: TodoEntity)

    @ViewBuilder
    func build(_ navigationPath: Binding<NavigationPath>) -> some View {
        switch self {
        case .home:
            let interactor = TodoInteractor()
            let router = TodoRouter(navigationPath: navigationPath)
            let presenter = TodoPresenter(interactor: interactor, router: router)
            
            TodoView(presenter: presenter)

        case .detail(let todo):
            TodoDetailView(todo: todo)
        }
    }
}

extension NavigationPath {
    mutating func goTo(_ factory: TodoModuleFactory) {
        self.append(factory)
    }
}
