//
//  HybridUserViewModel.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

/// Hybrid ViewModel demonstrating the power of combining Combine and async/await
/// - Uses Combine for reactive UI events (debounced search)
/// - Uses async/await for discrete operations (load, refresh, sync)
@MainActor
class HybridUserViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var users: [User] = []
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(userService: UserServiceProtocol) {
        self.userService = userService
        setupReactiveSearch()
    }

    // MARK: - Combine for Reactive Search

    /// Setup reactive search pipeline with debouncing
    /// This demonstrates Combine's strength for continuous UI events
    private func setupReactiveSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }

    // MARK: - Async/Await for One-Time Operations

    /// Load users using async/await
    /// Demonstrates converting Publisher to async for discrete operations
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Convert Combine publisher to async
            users = try await userService.fetchUsers().asyncThrows()

            // Initialize search results with all users
            if searchText.isEmpty {
                searchResults = users
            }
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
            print("Error loading users: \(error)")
        }
    }

    // MARK: - Hybrid Approach for Search

    /// Perform search using async/await triggered by Combine pipeline
    /// This is the hybrid pattern: Combine debounces, async performs the work
    private func performSearch(_ query: String) {
        // Cancel previous search task
        searchTask?.cancel()

        searchTask = Task { [weak self] in
            guard let self = self else { return }

            // Clear results for empty query
            guard !query.isEmpty else {
                await MainActor.run {
                    self.searchResults = self.users
                }
                return
            }

            do {
                // Use async/await for the search operation
                let results = try await self.userService
                    .searchUsers(query: query)
                    .asyncThrows()

                // Check for cancellation before updating UI
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.searchResults = results
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                }
                print("Search error: \(error)")
            }
        }
    }

    // MARK: - Structured Concurrency

    /// Refresh all data using task groups
    /// Demonstrates running multiple async operations concurrently
    func refreshAllData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await self.loadUserProfiles()
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to load profiles"
                    }
                }
            }

            group.addTask {
                do {
                    try await self.loadUserPreferences()
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to load preferences"
                    }
                }
            }

            group.addTask {
                do {
                    try await self.syncUserData()
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to sync data"
                    }
                }
            }
        }
    }

    // MARK: - Private Async Operations

    /// Convert Publisher to async for batch operations
    private func loadUserProfiles() async throws {
        let profiles = try await userService.fetchUserProfiles().asyncThrows()
        print("Loaded \(profiles.count) profiles")
    }

    private func loadUserPreferences() async throws {
        let preferences = try await userService.fetchUserPreferences().asyncThrows()
        print("Loaded preferences: \(preferences)")
    }

    private func syncUserData() async throws {
        try await userService.syncUserData().asyncThrows()
        print("Synced user data successfully")
    }

    // MARK: - Cleanup

    deinit {
        searchTask?.cancel()
        cancellables.removeAll()
    }
}
