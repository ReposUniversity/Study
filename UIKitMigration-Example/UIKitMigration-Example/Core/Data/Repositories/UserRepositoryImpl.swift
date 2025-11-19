//
//  UserRepositoryImpl.swift
//  UIKitMigration-Example
//
//  Data Layer - Repository Implementation (Adapter pattern)
//

import Foundation

// MARK: - User Repository Implementation

final class UserRepositoryImpl: UserRepository {
    private let legacyService: LegacyUserService

    init(legacyService: LegacyUserService = LegacyUserService()) {
        self.legacyService = legacyService
    }

    // Adapter method: Legacy -> Domain
    private func toDomain(_ legacyUser: LegacyUser) -> User {
        User(
            id: legacyUser.userId,
            name: legacyUser.userName,
            email: legacyUser.userEmail,
            profileImageURL: legacyUser.profileImagePath.flatMap { URL(string: $0) },
            isActive: legacyUser.isActive,
            lastLoginDate: legacyUser.lastLoginDate
        )
    }

    // Adapter method: Domain -> Legacy
    private func toLegacy(_ user: User) -> LegacyUser {
        LegacyUser(
            userId: user.id,
            userName: user.name,
            userEmail: user.email,
            profileImagePath: user.profileImageURL?.absoluteString,
            isActive: user.isActive,
            lastLoginDate: user.lastLoginDate
        )
    }

    func fetchUsers() async throws -> [User] {
        try await withCheckedThrowingContinuation { continuation in
            legacyService.fetchUsers { legacyUsers, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let legacyUsers = legacyUsers {
                    let users = legacyUsers.map { self.toDomain($0) }
                    continuation.resume(returning: users)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func fetchUser(id: String) async throws -> User? {
        let users = try await fetchUsers()
        return users.first { $0.id == id }
    }

    func updateUser(_ user: User) async throws {
        let legacyUser = toLegacy(user)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            legacyService.updateUser(legacyUser) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteUser(id: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            legacyService.deleteUser(withId: id) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func getCurrentUser() async -> User? {
        guard let currentLegacyUser = legacyService.currentUser else { return nil }
        return toDomain(currentLegacyUser)
    }
}
