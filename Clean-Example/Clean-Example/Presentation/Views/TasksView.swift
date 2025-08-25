//
//  TasksView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel: TasksViewModel

    init(viewModel: TasksViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                taskInputSection
                taskListSection
            }
            .navigationTitle("Tasks")
            .onAppear {
                viewModel.loadTasks()
            }
        }
    }

    private var taskInputSection: some View {
        VStack {
            TextField("Enter task title", text: $viewModel.newTaskTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    viewModel.addTask()
                }
            
            Button("Add Task") {
                viewModel.addTask()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    private var taskListSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.tasks.isEmpty {
                Text("No tasks yet. Add your first task above!")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.tasks, id: \.id) { task in
                    TaskRowView(task: task) {
                        viewModel.toggleTask(task)
                    }
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: TaskEntity
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                Text(task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}