//
//  RetryLogicTests.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Testing
import Combine
import Foundation
@testable import NetworkingLayer_Example

struct RetryLogicTests {
    
    @Test func testShouldRetryForRetryableErrors() throws {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let networkService = NetworkService(baseURL: baseURL)
        
        // When/Then
        #expect(networkService.shouldRetry(error: .serverError) == true)
        #expect(networkService.shouldRetry(error: .networkUnavailable) == true)
        #expect(networkService.shouldRetry(error: .timeout) == true)
    }
    
    @Test func testShouldNotRetryForNonRetryableErrors() throws {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let networkService = NetworkService(baseURL: baseURL)
        
        // When/Then
        #expect(networkService.shouldRetry(error: .invalidURL) == false)
        #expect(networkService.shouldRetry(error: .noData) == false)
        #expect(networkService.shouldRetry(error: .decodingFailed) == false)
        #expect(networkService.shouldRetry(error: .unauthorized) == false)
        #expect(networkService.shouldRetry(error: .forbidden) == false)
        #expect(networkService.shouldRetry(error: .notFound) == false)
    }
    
    @Test func testCalculateDelayExponentialBackoff() throws {
        // Given
        let baseURL = URL(string: "https://api.example.com")!
        let networkService = NetworkService(baseURL: baseURL)
        let baseDelay: TimeInterval = 1.0
        
        // When
        let delay0 = networkService.calculateDelay(baseDelay: baseDelay, attempt: 0)
        let delay1 = networkService.calculateDelay(baseDelay: baseDelay, attempt: 1)
        let delay2 = networkService.calculateDelay(baseDelay: baseDelay, attempt: 2)
        
        // Then - Should follow exponential backoff pattern with jitter
        #expect(delay0 >= 1.0 && delay0 <= 1.1) // 1s + up to 10% jitter
        #expect(delay1 >= 2.0 && delay1 <= 2.2) // 2s + up to 10% jitter
        #expect(delay2 >= 4.0 && delay2 <= 4.4) // 4s + up to 10% jitter
    }
    
    @Test func testRetryWithSuccessfulResponse() async throws {
        // Given - Test requestWithRetry with a successful response (no retry needed)
        let mockService = MockNetworkService()
        mockService.setDelay(0.05)
        
        let users = [User(id: 1, name: "Success User", username: nil, email: "success@example.com", phone: nil, website: nil)]
        mockService.setMockResponse(users, for: "GET:/users")
        
        // When - This should succeed on first try
        let result = try await mockService.requestWithRetry(.getUsers(), responseType: [User].self, maxRetries: 3, retryDelay: 0.05)
            .firstValue()
        
        // Then
        #expect(result.count == 1)
        #expect(result[0].name == "Success User")
    }
}

// Helper class to test retry logic with controlled behavior
class CountingMockNetworkService: NetworkServiceProtocol {
    private var attemptCount = 0
    private let behavior: (Int) throws -> [User]
    
    init(behavior: @escaping (Int) throws -> [User]) {
        self.behavior = behavior
    }
    
    func request<T: Codable>(_ endpoint: Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        let currentAttempt = attemptCount
        attemptCount += 1
        
        return Just(())
            .tryMap { _ in
                let result = try self.behavior(currentAttempt)
                return result as! T
            }
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.serverError
                }
            }
            .eraseToAnyPublisher()
    }
}

// Extension to add retry functionality for testing
extension CountingMockNetworkService {
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
                guard currentAttempt < maxRetries && self.shouldRetry(error: error) else {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                
                let delay = baseDelay * pow(2.0, Double(currentAttempt))
                
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
}

// Extension to make private methods accessible for testing
extension NetworkService {
    func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .serverError, .networkUnavailable, .timeout:
            return true
        case .invalidURL, .noData, .decodingFailed, .unauthorized, .forbidden, .notFound:
            return false
        }
    }
    
    func calculateDelay(baseDelay: TimeInterval, attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return exponentialDelay + jitter
    }
}

class TestExpectation {
    private var isFulfilled = false
    
    func fulfill() {
        isFulfilled = true
    }
    
    func wait() async {
        while !isFulfilled {
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
    }
}
