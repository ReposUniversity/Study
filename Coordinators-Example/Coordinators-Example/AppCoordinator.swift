//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: SheetDestination?
    @Published var fullScreenCover: FullScreenDestination?

    enum SheetDestination {
        case settings
        case profile(userId: String)
    }

    enum FullScreenDestination {
        case onboarding
        case camera
    }

    func push(_ destination: Destination) {
        path.append(destination)
    }

    func presentSheet(_ sheet: SheetDestination) {
        self.sheet = sheet
    }

    func dismiss() {
        sheet = nil
        fullScreenCover = nil
    }
}
