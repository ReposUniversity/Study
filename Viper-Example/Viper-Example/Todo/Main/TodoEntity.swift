//
//  Entity.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//


//[
//  {
//    "userId": 1,
//    "id": 1,
//    "title": "delectus aut autem",
//    "completed": false
//  }
//]

import Foundation

struct TodoEntity: Decodable, Hashable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}
