//
//  UserListView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct UserListView: View {
    @StateObject private var store: UserStore
    @State private var searchText = ""
    @State private var selectedUserId: UUID?

    init(userService: UserServiceProtocol) {
        _store = StateObject(wrappedValue: UserStore(userService: userService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText) { query in
                    store.dispatch(.searchUsers(query))
                }
                .padding(.vertical, 8)

                if store.state.isLoading && store.state.users.isEmpty {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = store.state.errorMessage {
                    EmptyStateView(
                        message: error,
                        systemImage: "exclamationmark.triangle"
                    ) {
                        store.dispatch(.loadUsers)
                    }
                } else if store.state.filteredUsers.isEmpty {
                    EmptyStateView(
                        message: searchText.isEmpty ? "No users available" : "No users found",
                        systemImage: "person.slash"
                    )
                } else {
                    List {
                        ForEach(store.state.filteredUsers) { user in
                            Button(action: {
                                selectedUserId = user.id
                                store.dispatch(.selectUser(user.id))
                            }) {
                                UserRowView(user: user)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let user = store.state.filteredUsers[index]
                                store.dispatch(.deleteUser(user.id))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        store.dispatch(.refreshUsers)
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            }
            .navigationTitle("Users")
            .navigationDestination(item: $selectedUserId) { userId in
                if let user = store.state.users.first(where: { $0.id == userId }) {
                    UserDetailView(user: user)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.state.isLoading {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                if store.state.users.isEmpty {
                    store.dispatch(.loadUsers)
                }
            }
        }
    }
}

// MARK: - UUID Identifiable Extension

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
