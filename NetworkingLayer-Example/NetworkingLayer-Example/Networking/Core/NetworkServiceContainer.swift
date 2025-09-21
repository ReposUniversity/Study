//
//  NetworkServiceContainer.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import SwiftUI

class NetworkServiceContainer: ObservableObject {
    let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    static func production() -> NetworkServiceContainer {
        let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
        // Disable system proxies to avoid local proxy interception (e.g., 127.0.0.1:9090)
        let networkService = NetworkService(baseURL: baseURL, disableSystemProxies: true)
        return NetworkServiceContainer(networkService: networkService)
    }
    
    static func mock() -> NetworkServiceContainer {
        let mockService = MockNetworkService()
        mockService.setupUsersMock()
        return NetworkServiceContainer(networkService: mockService)
    }
}

// MARK: - Environment Key
private struct NetworkServiceKey: EnvironmentKey {
    static let defaultValue = NetworkServiceContainer.production()
}

extension EnvironmentValues {
    var networkService: NetworkServiceContainer {
        get { self[NetworkServiceKey.self] }
        set { self[NetworkServiceKey.self] = newValue }
    }
}