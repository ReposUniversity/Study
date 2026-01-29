//
//  ServiceProtocols.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

// MARK: - Network Service Protocol

enum APIEndpoint {
    case getUser
    case saveUser(User)
}

protocol NetworkServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError>
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - User Service Protocol

protocol UserServiceProtocol {
    func loadUser() -> AnyPublisher<User, Error>
    func saveUser(_ user: User) -> AnyPublisher<User, Error>
}

// MARK: - Real Implementations

class RealNetworkService: NetworkServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        // Simulate network delay
        return Future<T, NetworkError> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                switch endpoint {
                case .getUser:
                    if let user = User(id: UUID(), name: "Real User", email: "real@example.com") as? T {
                        promise(.success(user))
                    } else {
                        promise(.failure(.decodingError))
                    }
                case .saveUser(let user):
                    if let savedUser = user as? T {
                        promise(.success(savedUser))
                    } else {
                        promise(.failure(.decodingError))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

class RealUserService: UserServiceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func loadUser() -> AnyPublisher<User, Error> {
        networkService.request(.getUser, responseType: User.self)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func saveUser(_ user: User) -> AnyPublisher<User, Error> {
        networkService.request(.saveUser(user), responseType: User.self)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock Implementations

class MockNetworkService: NetworkServiceProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        return Future<T, NetworkError> { promise in
            switch endpoint {
            case .getUser:
                if let user = User(id: UUID(), name: "Mock User", email: "mock@test.com") as? T {
                    promise(.success(user))
                } else {
                    promise(.failure(.decodingError))
                }
            case .saveUser(let user):
                if let savedUser = user as? T {
                    promise(.success(savedUser))
                } else {
                    promise(.failure(.decodingError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

class MockUserService: UserServiceProtocol {
    func loadUser() -> AnyPublisher<User, Error> {
        Just(User(id: UUID(), name: "Mock User", email: "mock@test.com"))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func saveUser(_ user: User) -> AnyPublisher<User, Error> {
        Just(user)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
