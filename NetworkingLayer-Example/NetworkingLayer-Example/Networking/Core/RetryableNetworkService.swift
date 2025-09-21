//
//  RetryableNetworkService.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

extension NetworkService {
    func requestWithRetry<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
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

// MARK: - Convenience methods
extension NetworkServiceProtocol {
    func requestWithRetry<T: Codable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        guard let networkService = self as? NetworkService else {
            return request(endpoint, responseType: responseType)
        }
        return networkService.requestWithRetry(endpoint, responseType: responseType)
    }
}