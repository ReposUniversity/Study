//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation

extension AppCoordinator {
    func handle(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        switch components.path {
        case "/profile":
            if let userId = components.queryItems?.first(where: { $0.name == "userId" })?.value {
                push(.profile(userId: userId))
            }
        case "/settings":
            presentSheet(.settings)
        case "/detail":
            if let itemIdString = components.queryItems?.first(where: { $0.name == "itemId" })?.value,
               let itemId = UUID(uuidString: itemIdString) {
                push(.detail(itemId: itemId))
            }
        default:
            push(.home)
        }
    }
}
