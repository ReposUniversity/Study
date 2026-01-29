//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

enum Destination: Hashable {
    case home
    case profile(userId: String)
    case settings
    case detail(itemId: UUID)

    var id: String {
        switch self {
        case .home: return "home"
        case .profile(let userId): return "profile_\(userId)"
        case .settings: return "settings"
        case .detail(let itemId): return "detail_\(itemId.uuidString)"
        }
    }
}
