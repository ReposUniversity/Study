//
//  ContentView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct TodoView: View {
    
    @ObservedObject var presenter: TodoPresenter

    var body: some View {
        List {
            ForEach(presenter.todos, id: \.id) { todo in
                HStack {
                    Text(todo.title)
                        .font(.headline)
                        .padding()
                    
                    Text(todo.completed ? "✅" : "❌")
                        .foregroundColor(todo.completed ? .green : .red)
                        .font(.title2)
                }.onTapGesture {
                    presenter.startDetail(for: todo)
                }
            }
        }
        .onAppear {
            Task {
                await presenter.loadTodos()
            }
        }
    }
}

