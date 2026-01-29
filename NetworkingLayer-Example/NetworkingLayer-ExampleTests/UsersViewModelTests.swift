//
//  UsersViewModelTests.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Testing
import Combine
@testable import NetworkingLayer_Example

@MainActor
struct UsersViewModelTests {
    
    @Test func testLoadUsersFailure() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setDelay(0.05) // Shorter delay for tests
        mockService.setMockError(.networkUnavailable, for: "GET:/users")
        let viewModel = UsersViewModel(networkService: mockService)
        
        // When
        viewModel.loadUsers()
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        #expect(viewModel.users.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == "Network unavailable")
        #expect(viewModel.showErrorAlert == true)
    }
    
    @Test func testCreateUserSuccess() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setDelay(0.05) // Shorter delay for tests
        let newUser = User(id: 3, name: "New User", username: "newuser", email: "new@example.com", phone: nil, website: nil)
        mockService.setMockResponse(newUser, for: "POST:/users")
        
        let viewModel = UsersViewModel(networkService: mockService)
        viewModel.users = [
            User(id: 1, name: "Existing User", username: "existing", email: "existing@example.com", phone: nil, website: nil)
        ]
        
        // When
        viewModel.createUser(name: "New User", email: "new@example.com")
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        #expect(viewModel.users.count == 2)
        #expect(viewModel.users.last?.name == "New User")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testCreateUserFailure() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setDelay(0.05) // Shorter delay for tests
        mockService.setMockError(.serverError, for: "POST:/users")
        let viewModel = UsersViewModel(networkService: mockService)
        
        // When
        viewModel.createUser(name: "New User", email: "new@example.com")
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        #expect(viewModel.users.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == "Server error occurred")
        #expect(viewModel.showErrorAlert == true)
    }
    
    @Test func testDeleteUserSuccess() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setDelay(0.05) // Shorter delay for tests
        mockService.setMockResponse(EmptyResponse(), for: "DELETE:/users/1")
        
        let userToDelete = User(id: 1, name: "User to Delete", username: "delete", email: "delete@example.com", phone: nil, website: nil)
        let remainingUser = User(id: 2, name: "Remaining User", username: "remain", email: "remain@example.com", phone: nil, website: nil)
        
        let viewModel = UsersViewModel(networkService: mockService)
        viewModel.users = [userToDelete, remainingUser]
        
        // When
        viewModel.deleteUser(userToDelete)
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        #expect(viewModel.users.count == 1)
        #expect(viewModel.users.first?.name == "Remaining User")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testDeleteUserFailure() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setDelay(0.05) // Shorter delay for tests
        mockService.setMockError(.forbidden, for: "DELETE:/users/1")
        
        let userToDelete = User(id: 1, name: "User to Delete", username: "delete", email: "delete@example.com", phone: nil, website: nil)
        let viewModel = UsersViewModel(networkService: mockService)
        viewModel.users = [userToDelete]
        
        // When
        viewModel.deleteUser(userToDelete)
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        #expect(viewModel.users.count == 1) // User should still be there
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == "Access forbidden")
        #expect(viewModel.showErrorAlert == true)
    }
    
    @Test func testLoadingStatesDuringOperation() async throws {
        // Given
        let mockService = MockNetworkService()
        mockService.setDelay(0.2) // Longer delay to test loading states
        mockService.setMockResponse([User](), for: "GET:/users")
        
        let viewModel = UsersViewModel(networkService: mockService)
        
        // When
        viewModel.loadUsers()
        
        // Then - Should be loading initially
        #expect(viewModel.isLoading == true)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then - Should not be loading anymore
        #expect(viewModel.isLoading == false)
    }
}
