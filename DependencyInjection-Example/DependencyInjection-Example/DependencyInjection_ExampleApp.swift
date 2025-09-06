//
//  DependencyInjection_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

@main
struct DependencyInjection_ExampleApp: App {
    
    init() {
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.userService, resolvedUserService())
                .environment(\.networkService, resolvedNetworkService())
        }
    }
    
    // MARK: - Dependency Setup
    
    private func setupDependencies() {
        let container = DIContainer.shared
        
        // Register network service
        let networkService = createNetworkService()
        container.register(NetworkServiceProtocol.self, implementation: networkService)
        
        // Register user service
        let userService = createUserService(networkService: networkService)
        container.register(UserServiceProtocol.self, implementation: userService)
    }
    
    private func createNetworkService() -> NetworkServiceProtocol {
        #if DEBUG
        // Use mock in debug mode for faster development
        return MockNetworkService()
        #else
        // Use real service in release
        return RealNetworkService()
        #endif
    }
    
    private func createUserService(networkService: NetworkServiceProtocol) -> UserServiceProtocol {
        #if DEBUG
        // For debug, you can choose between mock and real
        // Comment/uncomment as needed for testing
        return MockUserService()
        // return RealUserService(networkService: networkService)
        #else
        // Always use real service in release
        return RealUserService(networkService: networkService)
        #endif
    }
    
    // MARK: - Service Resolution
    
    private func resolvedUserService() -> UserServiceProtocol {
        return DIContainer.shared.resolve(UserServiceProtocol.self) ?? MockUserService()
    }
    
    private func resolvedNetworkService() -> NetworkServiceProtocol {
        return DIContainer.shared.resolve(NetworkServiceProtocol.self) ?? MockNetworkService()
    }
}
