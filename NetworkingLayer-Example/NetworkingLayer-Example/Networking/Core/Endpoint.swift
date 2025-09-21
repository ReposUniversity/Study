//
//  Endpoint.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let parameters: [String: Any]?
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    func url(baseURL: URL) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        
        if method == .GET, let parameters = parameters {
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        return components?.url
    }
    
    func urlRequest(baseURL: URL) -> URLRequest? {
        guard let url = url(baseURL: baseURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if method != .GET, let parameters = parameters {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                request.httpBody = jsonData
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                return nil
            }
        }
        
        return request
    }
}

// MARK: - API Endpoints
extension Endpoint {
    static func getUsers() -> Endpoint {
        Endpoint(
            path: "/users",
            method: .GET,
            headers: ["Content-Type": "application/json"],
            parameters: nil
        )
    }
    
    static func createUser(name: String, email: String) -> Endpoint {
        Endpoint(
            path: "/users",
            method: .POST,
            headers: ["Content-Type": "application/json"],
            parameters: ["name": name, "email": email]
        )
    }
    
    static func getUser(id: Int) -> Endpoint {
        Endpoint(
            path: "/users/\(id)",
            method: .GET,
            headers: ["Content-Type": "application/json"],
            parameters: nil
        )
    }
    
    static func deleteUser(id: Int) -> Endpoint {
        Endpoint(
            path: "/users/\(id)",
            method: .DELETE,
            headers: ["Content-Type": "application/json"],
            parameters: nil
        )
    }
}