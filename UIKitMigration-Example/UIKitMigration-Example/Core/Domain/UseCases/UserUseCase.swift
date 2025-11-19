//
//  UserUseCase.swift
//  UIKitMigration-Example
//
//  Domain Layer Use Case
//

import Foundation

// MARK: - User Use Case

final class UserUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func fetchUsers() async throws -> [User] {
        try await repository.fetchUsers()
    }

    func fetchUser(id: String) async throws -> User? {
        try await repository.fetchUser(id: id)
    }

    func updateUser(_ user: User) async throws {
        try await repository.updateUser(user)
    }

    func deleteUser(id: String) async throws {
        try await repository.deleteUser(id: id)
    }

    func getCurrentUser() async -> User? {
        await repository.getCurrentUser()
    }
}
