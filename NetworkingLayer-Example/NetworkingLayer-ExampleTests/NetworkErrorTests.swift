//
//  NetworkErrorTests.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Testing
import Foundation
import Combine
@testable import NetworkingLayer_Example

struct NetworkErrorTests {
    
    @Test func testNetworkErrorDescriptions() throws {
        // Test all error cases have proper descriptions
        #expect(NetworkError.invalidURL.errorDescription == "Invalid URL")
        #expect(NetworkError.noData.errorDescription == "No data received")
        #expect(NetworkError.decodingFailed.errorDescription == "Failed to decode response")
        #expect(NetworkError.serverError.errorDescription == "Server error occurred")
        #expect(NetworkError.networkUnavailable.errorDescription == "Network unavailable")
        #expect(NetworkError.unauthorized.errorDescription == "Unauthorized access")
        #expect(NetworkError.forbidden.errorDescription == "Access forbidden")
        #expect(NetworkError.notFound.errorDescription == "Resource not found")
        #expect(NetworkError.timeout.errorDescription == "Request timeout")
    }
    
    @Test func testNetworkErrorEquality() throws {
        // Test that same error types are equal
        #expect(NetworkError.invalidURL == NetworkError.invalidURL)
        #expect(NetworkError.serverError == NetworkError.serverError)
        
        // Test that different error types are not equal
        #expect(NetworkError.invalidURL != NetworkError.serverError)
        #expect(NetworkError.networkUnavailable != NetworkError.timeout)
    }
    
    @Test func testNetworkErrorIsLocalizedError() throws {
        let error: LocalizedError = NetworkError.networkUnavailable
        #expect(error.errorDescription == "Network unavailable")
    }
    
    @Test func testAllErrorCasesAreCovered() throws {
        // This test ensures we don't miss any cases when adding new errors
        let allErrors: [NetworkError] = [
            .invalidURL,
            .noData,
            .decodingFailed,
            .serverError,
            .networkUnavailable,
            .unauthorized,
            .forbidden,
            .notFound,
            .timeout
        ]
        
        // Each error should have a non-empty description
        for error in allErrors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

struct NetworkServiceErrorHandlingTests {
    
    @Test func testURLErrorMapping() async throws {
        // Given
        let mockService = URLErrorMockNetworkService()
        
        // Test timeout error mapping
        mockService.simulateURLError(.timedOut)
        await #expect(throws: NetworkError.timeout) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
        
        // Test network unavailable error mapping
        mockService.simulateURLError(.notConnectedToInternet)
        await #expect(throws: NetworkError.networkUnavailable) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
        
        // Test other network errors
        mockService.simulateURLError(.cannotFindHost)
        await #expect(throws: NetworkError.networkUnavailable) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
    }
    
    @Test func testHTTPStatusCodeMapping() async throws {
        // Given
        let mockService = HTTPStatusMockNetworkService()
        
        // Test 401 Unauthorized
        mockService.simulateHTTPStatus(401)
        await #expect(throws: NetworkError.unauthorized) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
        
        // Test 403 Forbidden
        mockService.simulateHTTPStatus(403)
        await #expect(throws: NetworkError.forbidden) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
        
        // Test 404 Not Found
        mockService.simulateHTTPStatus(404)
        await #expect(throws: NetworkError.notFound) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
        
        // Test 500 Server Error
        mockService.simulateHTTPStatus(500)
        await #expect(throws: NetworkError.serverError) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
    }
    
    @Test func testDecodingErrorMapping() async throws {
        // Given
        let mockService = DecodingErrorMockNetworkService()
        
        // When/Then - Should map decoding errors to decodingFailed
        await #expect(throws: NetworkError.decodingFailed) {
            try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        }
    }
    
    @Test func testSuccessfulResponse() async throws {
        // Given
        let mockService = SuccessMockNetworkService()
        let expectedUsers = [
            User(id: 1, name: "Test User", username: "test", email: "test@example.com", phone: nil, website: nil)
        ]
        mockService.setSuccessResponse(expectedUsers)
        
        // When
        let result = try await mockService.request(.getUsers(), responseType: [User].self).firstValue()
        
        // Then
        #expect(result.count == 1)
        #expect(result[0].name == "Test User")
    }
}

// Mock services for testing error handling scenarios
class URLErrorMockNetworkService: NetworkServiceProtocol {
    private var urlErrorCode: URLError.Code?
    
    func simulateURLError(_ code: URLError.Code) {
        self.urlErrorCode = code
    }
    
    func request<T: Codable>(_ endpoint: Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        return Fail(error: URLError(urlErrorCode ?? .unknown))
            .mapError { error -> NetworkError in
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        return NetworkError.timeout
                    case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
                        return NetworkError.networkUnavailable
                    default:
                        return NetworkError.networkUnavailable
                    }
                } else {
                    return NetworkError.networkUnavailable
                }
            }
            .eraseToAnyPublisher()
    }
}

class HTTPStatusMockNetworkService: NetworkServiceProtocol {
    private var statusCode: Int = 200
    
    func simulateHTTPStatus(_ code: Int) {
        self.statusCode = code
    }
    
    func request<T: Codable>(_ endpoint: Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        return Just(Data())
            .tryMap { _ -> T in
                switch self.statusCode {
                case 200...299:
                    // This will cause a decoding error since we're returning empty data
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: Data())
                case 401:
                    throw NetworkError.unauthorized
                case 403:
                    throw NetworkError.forbidden
                case 404:
                    throw NetworkError.notFound
                case 500...599:
                    throw NetworkError.serverError
                default:
                    throw NetworkError.serverError
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

class DecodingErrorMockNetworkService: NetworkServiceProtocol {
    func request<T: Codable>(_ endpoint: Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        let invalidJSON = "{ invalid json }"
        let data = invalidJSON.data(using: .utf8)!
        
        return Just(data)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { _ in NetworkError.decodingFailed }
            .eraseToAnyPublisher()
    }
}

class SuccessMockNetworkService: NetworkServiceProtocol {
    private var responseData: Data?
    
    func setSuccessResponse<T: Codable>(_ response: T) {
        do {
            self.responseData = try JSONEncoder().encode(response)
        } catch {
            self.responseData = nil
        }
    }
    
    func request<T: Codable>(_ endpoint: Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        guard let data = responseData else {
            return Fail(error: NetworkError.noData)
                .eraseToAnyPublisher()
        }
        
        return Just(data)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { _ in NetworkError.decodingFailed }
            .eraseToAnyPublisher()
    }
}
