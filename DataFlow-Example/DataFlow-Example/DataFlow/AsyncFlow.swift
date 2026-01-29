//
//  AsyncFlow.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - User Errors
enum UserError: Error, LocalizedError {
    case loadingFailed(String)
    case searchFailed(String)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load users: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
}

// MARK: - Async User View Model
@MainActor
class AsyncUserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var error: UserError?

    private let userService: UserServiceProtocol
    private var loadUsersTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    func loadUsers() {
        // Cancel previous loading task
        loadUsersTask?.cancel()

        loadUsersTask = Task {
            isLoading = true
            error = nil

            do {
                // Simulate network delay
                try await Task.sleep(nanoseconds: 500_000_000)

                // Check for cancellation
                try Task.checkCancellation()

                let fetchedUsers = try await userService.fetchUsers()

                // Check for cancellation before updating UI
                try Task.checkCancellation()

                users = fetchedUsers
            } catch is CancellationError {
                // Handle cancellation gracefully
                print("User loading cancelled")
            } catch {
                self.error = UserError.loadingFailed(error.localizedDescription)
            }

            isLoading = false
        }
    }

    func searchUsers(query: String) async {
        // Cancel previous search
        searchTask?.cancel()

        searchTask = Task {
            // Debounce search
            try? await Task.sleep(nanoseconds: 300_000_000)

            do {
                try Task.checkCancellation()

                let results = try await userService.searchUsers(query: query)

                try Task.checkCancellation()

                users = results
            } catch is CancellationError {
                print("Search cancelled")
            } catch {
                self.error = UserError.searchFailed(error.localizedDescription)
            }
        }
    }

    func refresh() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadUsersInternal()
            }

            // Add more concurrent operations
            group.addTask {
                await self.loadUserPreferences()
            }

            group.addTask {
                await self.syncAnalytics()
            }
        }
    }

    private func loadUsersInternal() async {
        isLoading = true
        error = nil

        do {
            let fetchedUsers = try await userService.fetchUsers()
            users = fetchedUsers
        } catch {
            self.error = UserError.loadingFailed(error.localizedDescription)
        }

        isLoading = false
    }

    private func loadUserPreferences() async {
        // Simulate loading preferences
        try? await Task.sleep(nanoseconds: 200_000_000)
        print("User preferences loaded")
    }

    private func syncAnalytics() async {
        // Simulate analytics sync
        try? await Task.sleep(nanoseconds: 150_000_000)
        print("Analytics synced")
    }

    deinit {
        // Cancel all tasks when view model is deallocated
        loadUsersTask?.cancel()
        searchTask?.cancel()
    }
}
