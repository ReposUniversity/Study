//
//  User.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    
    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}