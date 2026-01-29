//
//  DIContainer.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

class DIContainer {
    static let shared = DIContainer()
    private var services: [String: Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, service: T) {
        let key = String(describing: type)
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
}

// Protocol-based service registration
extension DIContainer {
    func register<T>(_ protocol: T.Type, implementation: T) {
        let key = String(describing: `protocol`)
        services[key] = implementation
    }
}