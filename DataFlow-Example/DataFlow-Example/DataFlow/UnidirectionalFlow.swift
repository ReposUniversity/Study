//
//  UnidirectionalFlow.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Actions
enum UserAction {
    case loadUsers
    case searchUsers(String)
    case selectUser(UUID)
    case refreshUsers
    case deleteUser(UUID)
    case clearSelection
}

// MARK: - State
struct UserState {
    var users: [User] = []
    var filteredUsers: [User] = []
    var selectedUser: User?
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
}

// MARK: - Store
@MainActor
class UserStore: ObservableObject {
    @Published private(set) var state = UserState()

    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(userService: UserServiceProtocol) {
        self.userService = userService
        setupDataFlow()
    }

    func dispatch(_ action: UserAction) {
        switch action {
        case .loadUsers:
            loadUsers()
        case .searchUsers(let query):
            searchUsers(query: query)
        case .selectUser(let userId):
            selectUser(userId: userId)
        case .refreshUsers:
            refreshUsers()
        case .deleteUser(let userId):
            deleteUser(userId: userId)
        case .clearSelection:
            state.selectedUser = nil
        }
    }

    private func setupDataFlow() {
        // Reactive search filtering
        $state
            .map(\.searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterUsers(searchText: searchText)
            }
            .store(in: &cancellables)
    }

    private func loadUsers() {
        state.isLoading = true
        state.errorMessage = nil

        userService.fetchUsers()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.state.isLoading = false
                    if case .failure(let error) = completion {
                        self?.state.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    self?.state.users = users
                    self?.filterUsers(searchText: self?.state.searchText ?? "")
                }
            )
            .store(in: &cancellables)
    }

    private func filterUsers(searchText: String) {
        if searchText.isEmpty {
            state.filteredUsers = state.users
        } else {
            state.filteredUsers = state.users.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                ($0.bio?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private func selectUser(userId: UUID) {
        state.selectedUser = state.users.first { $0.id == userId }
    }

    private func refreshUsers() {
        loadUsers()
    }

    private func deleteUser(userId: UUID) {
        state.users.removeAll { $0.id == userId }
        filterUsers(searchText: state.searchText)
        if state.selectedUser?.id == userId {
            state.selectedUser = nil
        }
    }

    private func searchUsers(query: String) {
        state.searchText = query
    }
}
