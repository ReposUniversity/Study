//
//  AsyncUserListView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct AsyncUserListView: View {
    @StateObject private var viewModel: AsyncUserViewModel
    @State private var searchText = ""
    @State private var selectedUser: User?

    init(userService: UserServiceProtocol) {
        _viewModel = StateObject(wrappedValue: AsyncUserViewModel(userService: userService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText) { query in
                    Task {
                        await viewModel.searchUsers(query: query)
                    }
                }
                .padding(.vertical, 8)

                if viewModel.isLoading {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.loadUsers()
                    }
                } else if viewModel.users.isEmpty {
                    EmptyStateView(
                        message: "No users available",
                        systemImage: "person.slash"
                    ) {
                        viewModel.loadUsers()
                    }
                } else {
                    List(viewModel.users) { user in
                        Button(action: {
                            selectedUser = user
                        }) {
                            UserRowView(user: user)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Users (Async)")
            .navigationDestination(item: $selectedUser) { user in
                UserDetailView(user: user)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                viewModel.loadUsers()
            }
        }
    }
}
