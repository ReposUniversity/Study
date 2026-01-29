//
//  MockNetworkServiceTests.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import NetworkingLayer_Example

struct MockNetworkServiceTests {
    
    @Test func testMockServiceReturnsConfiguredResponse() async throws {
        // Given
        let mockService = MockNetworkService()
        let expectedUsers = [
            User(id: 1, name: "John Doe", username: "johndoe", email: "john@example.com", phone: nil, website: nil),
            User(id: 2, name: "Jane Smith", username: "janesmith", email: "jane@example.com", phone: nil, website: nil)
        ]
        mockService.setMockResponse(expectedUsers, for: "GET:/users")
        
        // When
        let result = try await mockService.request(.getUsers(), responseType: [User].self)
            .firstValue()
        
        // Then
        #expect(result.count == 2)
        #expect(result[0].name == "John Doe")
        #expect(result[1].email == "jane@example.com")
    }
    
    @Test func testMockServiceReturnsConfiguredError() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setMockError(.networkUnavailable, for: "GET:/users")
        
        // When/Then
        await #expect(throws: NetworkError.networkUnavailable) {
            try await mockService.request(.getUsers(), responseType: [User].self)
                .firstValue()
        }
    }
    
    @Test func testMockServiceReturnsNoDataErrorForUnconfiguredEndpoint() async throws {
        // Given
        let mockService = MockNetworkService()
        
        // When/Then
        await #expect(throws: NetworkError.noData) {
            try await mockService.request(.getUsers(), responseType: [User].self)
                .firstValue()
        }
    }
    
    @Test func testClearAllMocks() async throws {
        // Given
        let mockService = MockNetworkService()
        let testUsers = [User(id: 1, name: "Test User", username: nil, email: "test@example.com", phone: nil, website: nil)]
        mockService.setMockResponse(testUsers, for: "GET:/users")
        
        // When
        mockService.clearAllMocks()
        
        // Then
        await #expect(throws: NetworkError.noData) {
            try await mockService.request(.getUsers(), responseType: [User].self)
                .firstValue()
        }
    }
    
    @Test func testSetupUsersMock() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setupUsersMock()
        
        // When
        let users = try await mockService.request(.getUsers(), responseType: [User].self)
            .firstValue()
        
        // Then
        #expect(users.count == 2)
        #expect(users[0].name == "Leanne Graham")
        #expect(users[0].username == "Bret")
        #expect(users[1].name == "Ervin Howell")
    }
}

// Extension to convert Publisher to async/await for testing
extension Publisher {
    func firstValue() async throws -> Output {
        for try await value in self.values {
            return value
        }
        throw URLError(.cancelled)
    }
}
