//
//  MockNetworkService.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class MockNetworkService: NetworkServiceProtocol {
    private var mockResponses: [String: Data] = [:]
    private var mockErrors: [String: NetworkError] = [:]
    private var delay: TimeInterval = 0.1
    
    func setMockResponse<T: Codable>(_ response: T, for endpoint: String) {
        do {
            let data = try JSONEncoder().encode(response)
            mockResponses[endpoint] = data
            mockErrors.removeValue(forKey: endpoint)
        } catch {
            print("Failed to encode mock response: \(error)")
        }
    }
    
    func setMockError(_ error: NetworkError, for endpoint: String) {
        mockErrors[endpoint] = error
        mockResponses.removeValue(forKey: endpoint)
    }
    
    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }
    
    func clearAllMocks() {
        mockResponses.removeAll()
        mockErrors.removeAll()
    }
    
    func request<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        let endpointKey = "\(endpoint.method.rawValue):\(endpoint.path)"
        
        return Just(())
            .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
            .tryMap { _ -> T in
                // Check if there's a mock error for this endpoint
                if let error = self.mockErrors[endpointKey] {
                    throw error
                }
                
                // Check if there's mock data for this endpoint
                guard let data = self.mockResponses[endpointKey] else {
                    throw NetworkError.noData
                }
                
                // Decode the mock response
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingFailed
                }
            }
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.decodingFailed
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Retry Logic Support
extension MockNetworkService {
    func requestWithRetry<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 0.1
    ) -> AnyPublisher<T, NetworkError> {
        return requestWithExponentialBackoff(
            endpoint,
            responseType: responseType,
            maxRetries: maxRetries,
            baseDelay: retryDelay,
            currentAttempt: 0
        )
    }
    
    private func requestWithExponentialBackoff<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type,
        maxRetries: Int,
        baseDelay: TimeInterval,
        currentAttempt: Int
    ) -> AnyPublisher<T, NetworkError> {
        return request(endpoint, responseType: responseType)
            .catch { error -> AnyPublisher<T, NetworkError> in
                // Only retry for specific errors and if we haven't exceeded max retries
                guard currentAttempt < maxRetries && self.shouldRetry(error: error) else {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                
                // Calculate exponential backoff with jitter
                let delay = self.calculateDelay(
                    baseDelay: baseDelay,
                    attempt: currentAttempt
                )
                
                return Just(())
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                    .flatMap { _ in
                        self.requestWithExponentialBackoff(
                            endpoint,
                            responseType: responseType,
                            maxRetries: maxRetries,
                            baseDelay: baseDelay,
                            currentAttempt: currentAttempt + 1
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .serverError, .networkUnavailable, .timeout:
            return true
        case .invalidURL, .noData, .decodingFailed, .unauthorized, .forbidden, .notFound:
            return false
        }
    }
    
    private func calculateDelay(baseDelay: TimeInterval, attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return exponentialDelay + jitter
    }
}

// MARK: - Convenience methods for common mock scenarios
extension MockNetworkService {
    func setupUsersMock() {
        let mockUsers: [User] = [
            User(id: 1, name: "Leanne Graham", username: "Bret", email: "Sincere@april.biz", phone: "1-770-736-8031 x56442", website: "hildegard.org"),
            User(id: 2, name: "Ervin Howell", username: "Antonette", email: "Shanna@melissa.tv", phone: "010-692-6593 x09125", website: "anastasia.net")
        ]
        setMockResponse(mockUsers, for: "GET:/users")

        let newUser = User(id: 3, name: "New User", username: nil, email: "new@example.com", phone: nil, website: nil)
        setMockResponse(newUser, for: "POST:/users")
    }
    
    func setupNetworkErrorScenarios() {
        setMockError(.networkUnavailable, for: "GET:/users")
    }
}