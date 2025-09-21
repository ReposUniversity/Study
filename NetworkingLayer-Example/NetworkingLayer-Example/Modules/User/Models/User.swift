//
//  User.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let username: String?
    let email: String
    let phone: String?
    let website: String?
}

struct UsersResponse: Codable {
    let data: [User]
    let page: Int
    let perPage: Int
    let total: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case data, page, total
        case perPage = "per_page"
        case totalPages = "total_pages"
    }
}

// Empty response for DELETE requests that don't return data
struct EmptyResponse: Codable {}