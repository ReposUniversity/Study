//
//  EnvironmentInjection.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

// MARK: - User Service Environment Key

struct UserServiceKey: EnvironmentKey {
    static let defaultValue: UserServiceProtocol = MockUserService()
}

extension EnvironmentValues {
    var userService: UserServiceProtocol {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

// MARK: - Network Service Environment Key

struct NetworkServiceKey: EnvironmentKey {
    static let defaultValue: NetworkServiceProtocol = MockNetworkService()
}

extension EnvironmentValues {
    var networkService: NetworkServiceProtocol {
        get { self[NetworkServiceKey.self] }
        set { self[NetworkServiceKey.self] = newValue }
    }
}