//
//  ContentView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    private let userService = MockUserService()

    var body: some View {
        TabView {
            // Unidirectional Flow Example
            UserListView(userService: userService)
                .tabItem {
                    Label("Unidirectional", systemImage: "arrow.right.circle")
                }

            // Async Flow Example
            AsyncUserListView(userService: userService)
                .tabItem {
                    Label("Async", systemImage: "bolt.circle")
                }

            // State Sync Example
            StateSyncView()
                .tabItem {
                    Label("Multi-Source", systemImage: "arrow.triangle.merge")
                }

            // Resilient Data Flow Example
            ResilientFlowView(userService: userService)
                .tabItem {
                    Label("Resilient", systemImage: "lock.shield")
                }

            // Info Tab
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
        }
    }
}

// MARK: - State Sync View
struct StateSyncView: View {
    @StateObject private var synchronizer: StateSynchronizer

    init() {
        _synchronizer = StateObject(wrappedValue: StateSynchronizer(
            networkService: MockNetworkService(),
            localDatabase: MockLocalDatabase(),
            cacheService: MockCacheService()
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Sync Status
                syncStatusView

                Divider()

                // User List
                if synchronizer.combinedState.users.isEmpty {
                    EmptyStateView(
                        message: "No synchronized users",
                        systemImage: "person.2.slash"
                    )
                } else {
                    List(synchronizer.combinedState.users) { user in
                        UserRowView(user: user)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Multi-Source Sync")
        }
    }

    private var syncStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Sync Status:")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            if let lastSync = synchronizer.combinedState.lastSyncDate {
                Text("Last synced: \(formatDate(lastSync))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch synchronizer.combinedState.syncStatus {
        case .syncing:
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing")
            }
        case .synced:
            Label("Synced", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .error(let message):
            Label("Error: \(message)", systemImage: "xmark.circle.fill")
                .foregroundColor(.red)
        case .offline:
            Label("Offline", systemImage: "wifi.slash")
                .foregroundColor(.orange)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Resilient Flow View
struct ResilientFlowView: View {
    let userService: UserServiceProtocol

    var body: some View {
        NavigationStack {
            ResilientDataView(
                cacheKey: "resilient_users",
                dataSource: {
                    userService.fetchUsers()
                }
            ) { users in
                List(users) { user in
                    UserRowView(user: user)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Resilient Flow")
        }
    }
}

// MARK: - Info View
struct InfoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerView

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            title: "Unidirectional Flow",
                            icon: "arrow.right.circle",
                            description: "Demonstrates action-based state management where all state changes flow through explicit actions."
                        )

                        InfoSection(
                            title: "Async Flow",
                            icon: "bolt.circle",
                            description: "Shows structured concurrency with async/await, Task cancellation, and concurrent operations."
                        )

                        InfoSection(
                            title: "Multi-Source Sync",
                            icon: "arrow.triangle.merge",
                            description: "Synchronizes data from multiple sources (network, cache, database) into a single consistent state."
                        )

                        InfoSection(
                            title: "Resilient Flow",
                            icon: "shield.circle",
                            description: "Implements robust error handling with retry logic, fallbacks, and stale data awareness."
                        )
                    }

                    Divider()

                    keyFeaturesView
                }
                .padding()
            }
            .navigationTitle("Data Flow Patterns")
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SwiftUI Data Flow")
                .font(.title)
                .fontWeight(.bold)

            Text("Unidirectional, Async, and Resilient")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var keyFeaturesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Features")
                .font(.headline)

            FeatureBullet(text: "Single source of truth for predictable state")
            FeatureBullet(text: "Structured concurrency with proper cancellation")
            FeatureBullet(text: "Multi-source data synchronization")
            FeatureBullet(text: "Automatic retry and error recovery")
            FeatureBullet(text: "Stale data detection and handling")
            FeatureBullet(text: "Type-safe navigation and routing")
        }
    }
}

// MARK: - Info Section
struct InfoSection: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Feature Bullet
struct FeatureBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ContentView()
}
