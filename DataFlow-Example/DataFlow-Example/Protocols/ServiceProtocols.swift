//
//  ServiceProtocols.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

// MARK: - User Service Protocol
protocol UserServiceProtocol {
    func fetchUsers() -> AnyPublisher<[User], Error>
    func fetchUsers() async throws -> [User]
    func searchUsers(query: String) async throws -> [User]
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: UUID) async throws
}

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    var userUpdates: AnyPublisher<[User], Never> { get }
    func syncUsers(_ users: [User]) async throws
}

// MARK: - Local Database Protocol
protocol LocalDatabaseProtocol {
    var userUpdates: AnyPublisher<[User], Never> { get }
    func saveUsers(_ users: [User]) async throws
    func loadUsers() async throws -> [User]
    func deleteUser(id: UUID) async throws
}

// MARK: - Cache Service Protocol
protocol CacheServiceProtocol {
    var userUpdates: AnyPublisher<[User], Never> { get }
    func updateUsers(_ users: [User]) async throws
    func getCachedUsers() async -> [User]
    func clearCache() async
}
