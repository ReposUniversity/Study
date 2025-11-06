//
//  User.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

// MARK: - User Models

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let email: String
    let avatar: String?

    init(id: UUID = UUID(), name: String, email: String, avatar: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatar = avatar
    }
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    let bio: String
    let avatarURL: URL?
    let joinDate: Date

    init(
        id: UUID = UUID(),
        bio: String,
        avatarURL: URL? = nil,
        joinDate: Date = Date()
    ) {
        self.id = id
        self.bio = bio
        self.avatarURL = avatarURL
        self.joinDate = joinDate
    }
}

struct UserPreferences: Codable, Equatable {
    let theme: String
    let language: String
    let notifications: Bool

    init(
        theme: String = "light",
        language: String = "en",
        notifications: Bool = true
    ) {
        self.theme = theme
        self.language = language
        self.notifications = notifications
    }
}

// MARK: - Mock Data Extensions

extension User {
    static let mockUsers: [User] = [
        User(name: "Alice Johnson", email: "alice@example.com", avatar: "person.circle.fill"),
        User(name: "Bob Smith", email: "bob@example.com", avatar: "person.circle.fill"),
        User(name: "Charlie Brown", email: "charlie@example.com", avatar: "person.circle.fill"),
        User(name: "Diana Prince", email: "diana@example.com", avatar: "person.circle.fill"),
        User(name: "Ethan Hunt", email: "ethan@example.com", avatar: "person.circle.fill"),
        User(name: "Fiona Green", email: "fiona@example.com", avatar: "person.circle.fill"),
        User(name: "George Wilson", email: "george@example.com", avatar: "person.circle.fill"),
        User(name: "Hannah Montana", email: "hannah@example.com", avatar: "person.circle.fill")
    ]

    static func search(query: String, in users: [User]) -> [User] {
        guard !query.isEmpty else { return users }
        return users.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
}
