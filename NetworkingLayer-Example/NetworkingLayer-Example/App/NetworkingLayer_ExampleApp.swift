//
//  NetworkingLayer_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

@main
struct NetworkingLayer_ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.networkService, NetworkServiceContainer.production())
        }
    }
}
