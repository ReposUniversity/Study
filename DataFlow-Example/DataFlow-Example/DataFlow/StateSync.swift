//
//  StateSync.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Combined App State
struct CombinedAppState {
    var users: [User] = []
    var syncStatus: SyncStatus = .synced
    var lastSyncDate: Date?
}

enum SyncStatus {
    case syncing
    case synced
    case error(String)
    case offline
}

// MARK: - State Synchronizer
@MainActor
class StateSynchronizer: ObservableObject {
    @Published var combinedState = CombinedAppState()

    private let networkService: NetworkServiceProtocol
    private let localDatabase: LocalDatabaseProtocol
    private let cacheService: CacheServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "state.sync", qos: .userInitiated)

    init(
        networkService: NetworkServiceProtocol,
        localDatabase: LocalDatabaseProtocol,
        cacheService: CacheServiceProtocol
    ) {
        self.networkService = networkService
        self.localDatabase = localDatabase
        self.cacheService = cacheService

        setupStateSynchronization()
    }

    private func setupStateSynchronization() {
        // Sync users from multiple sources
        Publishers.CombineLatest3(
            networkService.userUpdates,
            localDatabase.userUpdates,
            cacheService.userUpdates
        )
        .debounce(for: .milliseconds(100), scheduler: syncQueue)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] networkUsers, localUsers, cachedUsers in
            self?.reconcileUserStates(
                network: networkUsers,
                local: localUsers,
                cached: cachedUsers
            )
        }
        .store(in: &cancellables)

        // Handle connectivity changes
        NotificationCenter.default.publisher(for: .networkConnectivityChanged)
            .sink { [weak self] _ in
                self?.handleConnectivityChange()
            }
            .store(in: &cancellables)
    }

    private func reconcileUserStates(
        network: [User],
        local: [User],
        cached: [User]
    ) {
        combinedState.syncStatus = .syncing

        var reconciledUsers: [User] = []

        // Create a merge strategy based on timestamps and priorities
        let allUserIds = Set(network.map(\.id))
            .union(Set(local.map(\.id)))
            .union(Set(cached.map(\.id)))

        for userId in allUserIds {
            let networkUser = network.first { $0.id == userId }
            let localUser = local.first { $0.id == userId }
            let cachedUser = cached.first { $0.id == userId }

            // Priority: Network > Local > Cache (if timestamps are recent)
            let reconciledUser = selectMostRecentUser(
                network: networkUser,
                local: localUser,
                cached: cachedUser
            )

            if let user = reconciledUser {
                reconciledUsers.append(user)
            }
        }

        combinedState.users = reconciledUsers
        combinedState.syncStatus = .synced
        combinedState.lastSyncDate = Date()

        // Propagate changes back to data sources
        propagateChanges(users: reconciledUsers)
    }

    private func selectMostRecentUser(
        network: User?,
        local: User?,
        cached: User?
    ) -> User? {
        let candidates = [network, local, cached].compactMap { $0 }

        return candidates.max { user1, user2 in
            user1.lastModified < user2.lastModified
        }
    }

    private func propagateChanges(users: [User]) {
        Task {
            // Update cache
            try? await cacheService.updateUsers(users)

            // Update local database
            try? await localDatabase.saveUsers(users)

            // Optionally sync back to network if needed
            if isConnectedToNetwork {
                try? await networkService.syncUsers(users)
            }
        }
    }

    private func handleConnectivityChange() {
        if isConnectedToNetwork {
            combinedState.syncStatus = .synced
            // Sync pending changes when connection is restored
            Task {
                await syncPendingChanges()
            }
        } else {
            combinedState.syncStatus = .offline
        }
    }

    private func syncPendingChanges() async {
        // Implement sync logic for offline changes
        print("Syncing pending changes...")
        try? await Task.sleep(nanoseconds: 500_000_000)
    }

    private var isConnectedToNetwork: Bool {
        // Simple implementation - in real app, use NWPathMonitor
        return true
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let networkConnectivityChanged = Notification.Name("networkConnectivityChanged")
}
