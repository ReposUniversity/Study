//
//  EndpointTests.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Testing
import Foundation
@testable import NetworkingLayer_Example

struct EndpointTests {
    
    let baseURL = URL(string: "https://api.example.com")!
    
    @Test func testGetUsersEndpoint() throws {
        // Given
        let endpoint = Endpoint.getUsers()
        
        // Then
        #expect(endpoint.path == "/users")
        #expect(endpoint.method == .GET)
        #expect(endpoint.headers?["Content-Type"] == "application/json")
        #expect(endpoint.parameters == nil)
    }
    
    @Test func testCreateUserEndpoint() throws {
        // Given
        let endpoint = Endpoint.createUser(name: "John Doe", email: "john@example.com")
        
        // Then
        #expect(endpoint.path == "/users")
        #expect(endpoint.method == .POST)
        #expect(endpoint.headers?["Content-Type"] == "application/json")
        #expect(endpoint.parameters?["name"] as? String == "John Doe")
        #expect(endpoint.parameters?["email"] as? String == "john@example.com")
    }
    
    @Test func testGetUserEndpoint() throws {
        // Given
        let userId = 123
        let endpoint = Endpoint.getUser(id: userId)
        
        // Then
        #expect(endpoint.path == "/users/123")
        #expect(endpoint.method == .GET)
        #expect(endpoint.headers?["Content-Type"] == "application/json")
        #expect(endpoint.parameters == nil)
    }
    
    @Test func testDeleteUserEndpoint() throws {
        // Given
        let userId = 456
        let endpoint = Endpoint.deleteUser(id: userId)
        
        // Then
        #expect(endpoint.path == "/users/456")
        #expect(endpoint.method == .DELETE)
        #expect(endpoint.headers?["Content-Type"] == "application/json")
        #expect(endpoint.parameters == nil)
    }
    
    @Test func testURLGenerationForGETRequest() throws {
        // Given
        let endpoint = Endpoint.getUsers()
        
        // When
        let generatedURL = endpoint.url(baseURL: baseURL)
        
        // Then
        let expectedURL = URL(string: "https://api.example.com/users")
        #expect(generatedURL == expectedURL)
    }
    
    @Test func testURLGenerationWithQueryParameters() throws {
        // Given
        let endpoint = Endpoint(
            path: "/users",
            method: .GET,
            headers: nil,
            parameters: ["page": 1, "limit": 10]
        )
        
        // When
        let generatedURL = endpoint.url(baseURL: baseURL)
        
        // Then
        #expect(generatedURL != nil)
        let urlComponents = URLComponents(url: generatedURL!, resolvingAgainstBaseURL: false)
        
        let pageItem = urlComponents?.queryItems?.first { $0.name == "page" }
        let limitItem = urlComponents?.queryItems?.first { $0.name == "limit" }
        
        #expect(pageItem?.value == "1")
        #expect(limitItem?.value == "10")
    }
    
    @Test func testURLRequestGenerationForGETRequest() throws {
        // Given
        let endpoint = Endpoint.getUsers()
        
        // When
        let urlRequest = endpoint.urlRequest(baseURL: baseURL)
        
        // Then
        #expect(urlRequest != nil)
        #expect(urlRequest?.httpMethod == "GET")
        #expect(urlRequest?.url?.absoluteString == "https://api.example.com/users")
        #expect(urlRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest?.timeoutInterval == 30)
    }
    
    @Test func testURLRequestGenerationForPOSTRequest() throws {
        // Given
        let endpoint = Endpoint.createUser(name: "John Doe", email: "john@example.com")
        
        // When
        let urlRequest = endpoint.urlRequest(baseURL: baseURL)
        
        // Then
        #expect(urlRequest != nil)
        #expect(urlRequest?.httpMethod == "POST")
        #expect(urlRequest?.url?.absoluteString == "https://api.example.com/users")
        #expect(urlRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        
        // Check body content
        #expect(urlRequest?.httpBody != nil)
        if let bodyData = urlRequest?.httpBody {
            let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            #expect(json?["name"] as? String == "John Doe")
            #expect(json?["email"] as? String == "john@example.com")
        }
    }
    
    @Test func testURLRequestGenerationWithCustomHeaders() throws {
        // Given
        let endpoint = Endpoint(
            path: "/users",
            method: .GET,
            headers: ["Authorization": "Bearer token123", "Custom-Header": "custom-value"],
            parameters: nil
        )
        
        // When
        let urlRequest = endpoint.urlRequest(baseURL: baseURL)
        
        // Then
        #expect(urlRequest != nil)
        #expect(urlRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
        #expect(urlRequest?.value(forHTTPHeaderField: "Custom-Header") == "custom-value")
    }
    
    @Test func testInvalidURLHandling() throws {
        // Given
        let invalidBaseURL = URL(string: "not-a-valid-url")!
        let endpoint = Endpoint.getUsers()
        
        // When
        let generatedURL = endpoint.url(baseURL: invalidBaseURL)
        
        // Then - Should still generate a URL (URLComponents is quite forgiving)
        #expect(generatedURL != nil)
    }
    
    @Test func testEmptyParametersHandling() throws {
        // Given
        let endpoint = Endpoint(
            path: "/users",
            method: .POST,
            headers: nil,
            parameters: [:]
        )
        
        // When
        let urlRequest = endpoint.urlRequest(baseURL: baseURL)
        
        // Then
        #expect(urlRequest != nil)
        #expect(urlRequest?.httpBody != nil)
        
        if let bodyData = urlRequest?.httpBody {
            let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
            #expect(json?.isEmpty == true)
        }
    }
}