//
//  MockUserService.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class MockUserService: UserServiceProtocol {
    private var users: [User] = User.mockUsers
    private let userSubject = PassthroughSubject<[User], Never>()

    func fetchUsers() -> AnyPublisher<[User], Error> {
        // Simulate network delay
        return Just(users)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchUsers() async throws -> [User] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return users
    }

    func searchUsers(query: String) async throws -> [User] {
        try await Task.sleep(nanoseconds: 300_000_000)

        if query.isEmpty {
            return users
        }

        return users.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query) ||
            ($0.bio?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func updateUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 200_000_000)

        if let index = users.firstIndex(where: { $0.id == user.id }) {
            var updatedUser = user
            updatedUser.lastModified = Date()
            users[index] = updatedUser
            userSubject.send(users)
            return updatedUser
        }

        throw NSError(domain: "MockUserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
    }

    func deleteUser(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        users.removeAll { $0.id == id }
        userSubject.send(users)
    }
}

// MARK: - Mock Network Service
class MockNetworkService: NetworkServiceProtocol {
    private let userSubject = PassthroughSubject<[User], Never>()

    var userUpdates: AnyPublisher<[User], Never> {
        userSubject.eraseToAnyPublisher()
    }

    func syncUsers(_ users: [User]) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        userSubject.send(users)
    }
}

// MARK: - Mock Local Database
class MockLocalDatabase: LocalDatabaseProtocol {
    private var storage: [User] = []
    private let userSubject = PassthroughSubject<[User], Never>()

    var userUpdates: AnyPublisher<[User], Never> {
        userSubject.eraseToAnyPublisher()
    }

    func saveUsers(_ users: [User]) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        storage = users
        userSubject.send(users)
    }

    func loadUsers() async throws -> [User] {
        try await Task.sleep(nanoseconds: 100_000_000)
        return storage
    }

    func deleteUser(id: UUID) async throws {
        storage.removeAll { $0.id == id }
        userSubject.send(storage)
    }
}

// MARK: - Mock Cache Service
class MockCacheService: CacheServiceProtocol {
    private var cache: [User] = []
    private let userSubject = PassthroughSubject<[User], Never>()

    var userUpdates: AnyPublisher<[User], Never> {
        userSubject.eraseToAnyPublisher()
    }

    func updateUsers(_ users: [User]) async throws {
        cache = users
        userSubject.send(users)
    }

    func getCachedUsers() async -> [User] {
        return cache
    }

    func clearCache() async {
        cache = []
        userSubject.send([])
    }
}
