//
//  UserService.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

// MARK: - Service Protocol

/// Service protocol supporting both Combine and async/await paradigms
protocol UserServiceProtocol {
    func fetchUsers() -> AnyPublisher<[User], Error>
    func searchUsers(query: String) -> AnyPublisher<[User], Error>
    func fetchUserProfiles() -> AnyPublisher<[UserProfile], Error>
    func fetchUserPreferences() -> AnyPublisher<UserPreferences, Error>
    func syncUserData() -> AnyPublisher<Void, Error>
}

// MARK: - Service Implementation

class UserService: UserServiceProtocol {

    // MARK: - Combine Publishers (wrapping async functions)

    func fetchUsers() -> AnyPublisher<[User], Error> {
        asyncToPublisher {
            try await self.fetchUsersAsync()
        }
    }

    func searchUsers(query: String) -> AnyPublisher<[User], Error> {
        asyncToPublisher {
            try await self.searchUsersAsync(query: query)
        }
    }

    func fetchUserProfiles() -> AnyPublisher<[UserProfile], Error> {
        asyncToPublisher {
            try await self.fetchUserProfilesAsync()
        }
    }

    func fetchUserPreferences() -> AnyPublisher<UserPreferences, Error> {
        asyncToPublisher {
            try await self.fetchUserPreferencesAsync()
        }
    }

    func syncUserData() -> AnyPublisher<Void, Error> {
        asyncToPublisher {
            try await self.syncUserDataAsync()
        }
    }

    // MARK: - Internal Async Implementations

    private func fetchUsersAsync() async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        return User.mockUsers
    }

    private func searchUsersAsync(query: String) async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        return User.search(query: query, in: User.mockUsers)
    }

    private func fetchUserProfilesAsync() async throws -> [UserProfile] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds

        return User.mockUsers.map { user in
            UserProfile(
                id: user.id,
                bio: "Bio for \(user.name)",
                avatarURL: nil,
                joinDate: Date().addingTimeInterval(-Double.random(in: 0...31536000))
            )
        }
    }

    private func fetchUserPreferencesAsync() async throws -> UserPreferences {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds

        return UserPreferences(
            theme: Bool.random() ? "light" : "dark",
            language: "en",
            notifications: Bool.random()
        )
    }

    private func syncUserDataAsync() async throws {
        // Simulate sync operation
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
    }
}
