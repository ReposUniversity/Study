//
//  User.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

struct User: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var avatarURL: URL?
    var bio: String?
    var lastModified: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        avatarURL: URL? = nil,
        bio: String? = nil,
        lastModified: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.bio = bio
        self.lastModified = lastModified
        self.isActive = isActive
    }
}

// MARK: - Mock Data
extension User {
    static let mockUsers: [User] = [
        User(
            name: "Alice Johnson",
            email: "alice@example.com",
            bio: "iOS Developer passionate about SwiftUI"
        ),
        User(
            name: "Bob Smith",
            email: "bob@example.com",
            bio: "Backend engineer who loves clean architecture"
        ),
        User(
            name: "Carol Williams",
            email: "carol@example.com",
            bio: "Product designer crafting delightful experiences"
        ),
        User(
            name: "David Brown",
            email: "david@example.com",
            bio: "Full-stack developer and open source contributor"
        ),
        User(
            name: "Eve Davis",
            email: "eve@example.com",
            bio: "DevOps engineer automating everything"
        )
    ]
}
