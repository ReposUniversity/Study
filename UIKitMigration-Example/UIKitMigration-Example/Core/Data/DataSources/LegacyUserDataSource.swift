//
//  LegacyUserDataSource.swift
//  UIKitMigration-Example
//
//  Data Layer - Legacy NSObject-based data source (simulates existing UIKit codebase)
//

import Foundation

// MARK: - Legacy User (NSObject-based for KVO compatibility)

@objc final class LegacyUser: NSObject {
    @objc dynamic var userId: String
    @objc dynamic var userName: String
    @objc dynamic var userEmail: String
    @objc dynamic var profileImagePath: String?
    @objc dynamic var isActive: Bool
    @objc dynamic var lastLoginDate: Date?

    init(
        userId: String,
        userName: String,
        userEmail: String,
        profileImagePath: String? = nil,
        isActive: Bool = true,
        lastLoginDate: Date? = nil
    ) {
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.profileImagePath = profileImagePath
        self.isActive = isActive
        self.lastLoginDate = lastLoginDate
        super.init()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let legacyUsersDidUpdate = Notification.Name("LegacyUsersDidUpdate")
    static let legacyCurrentUserDidChange = Notification.Name("LegacyCurrentUserDidChange")
}

// MARK: - Legacy User Service (Simulates existing callback-based service)
final class LegacyUserService: NSObject {
    private var users: [LegacyUser] = []
    private(set) var currentUser: LegacyUser?

    func fetchUsers(completion: @escaping ([LegacyUser]?, Error?) -> Void) {
        // Simulate async operation
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // Simulate API call
            let mockUsers = [
                LegacyUser(
                    userId: "1",
                    userName: "John Doe",
                    userEmail: "john@example.com",
                    profileImagePath: "https://example.com/john.jpg",
                    lastLoginDate: Date().addingTimeInterval(-3600)
                ),
                LegacyUser(
                    userId: "2",
                    userName: "Jane Smith",
                    userEmail: "jane@example.com",
                    profileImagePath: "https://example.com/jane.jpg",
                    lastLoginDate: Date().addingTimeInterval(-7200)
                )
            ]

            self.users = mockUsers

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .legacyUsersDidUpdate,
                    object: mockUsers
                )
                completion(mockUsers, nil)
            }
        }
    }

    func updateUser(_ user: LegacyUser, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            // Simulate API call
            if let index = self.users.firstIndex(where: { $0.userId == user.userId }) {
                self.users[index] = user

                if self.currentUser?.userId == user.userId {
                    self.currentUser = user
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .legacyCurrentUserDidChange,
                            object: user
                        )
                    }
                }
            }

            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }

    func deleteUser(withId userId: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            self.users.removeAll { $0.userId == userId }

            if self.currentUser?.userId == userId {
                self.currentUser = nil
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .legacyCurrentUserDidChange,
                        object: nil
                    )
                }
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .legacyUsersDidUpdate,
                    object: self.users
                )
                completion(nil)
            }
        }
    }

    func setCurrentUser(_ user: LegacyUser?) {
        currentUser = user
        NotificationCenter.default.post(
            name: .legacyCurrentUserDidChange,
            object: user
        )
    }
}
