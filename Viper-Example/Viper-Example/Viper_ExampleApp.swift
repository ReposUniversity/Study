//
//  Viper_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

@main
struct Viper_ExampleApp: App {
    @State var navigationPath = NavigationPath()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationPath) {
                TodoModuleFactory.home.build($navigationPath)
                    .navigationDestination(for: TodoModuleFactory.self) { factory in
                        factory.build($navigationPath)
                    }
            }
        }
    }
}
