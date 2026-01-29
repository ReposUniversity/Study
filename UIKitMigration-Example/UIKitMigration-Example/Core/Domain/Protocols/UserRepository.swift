//
//  UserRepository.swift
//  UIKitMigration-Example
//
//  Domain Layer Protocol (Repository Interface)
//

import Foundation

// MARK: - User Repository Protocol

protocol UserRepository {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: String) async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteUser(id: String) async throws
    func getCurrentUser() async -> User?
}
