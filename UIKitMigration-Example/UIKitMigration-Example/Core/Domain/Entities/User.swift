//
//  User.swift
//  UIKitMigration-Example
//
//  Core Domain Entity representing a User
//

import Foundation

// MARK: - Modern User (Domain Entity)

struct User: Identifiable, Equatable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: URL?
    let isActive: Bool
    let lastLoginDate: Date?

    init(
        id: String,
        name: String,
        email: String,
        profileImageURL: URL? = nil,
        isActive: Bool = true,
        lastLoginDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.isActive = isActive
        self.lastLoginDate = lastLoginDate
    }
}
