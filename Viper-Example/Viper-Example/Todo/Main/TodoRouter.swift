//
//  Router.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

protocol TodoRouterProtocol {
    func openDetail(for todo: TodoEntity)
}

class TodoRouter: TodoRouterProtocol {
    @Binding var navigationPath: NavigationPath
    
    init(navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
    }
    
    func openDetail(for todo: TodoEntity) {
        navigationPath.goTo(.detail(todo: todo))
    }
}

