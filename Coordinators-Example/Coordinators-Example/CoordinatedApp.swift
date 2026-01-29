//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct CoordinatedApp: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .sheet(item: Binding<SheetItem?>(
            get: { coordinator.sheet.map(SheetItem.init) },
            set: { _ in coordinator.dismiss() }
        )) { item in
            sheetView(for: item.destination)
        }
        .environmentObject(coordinator)
        .onOpenURL { url in
            coordinator.handle(url: url)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .home: 
            HomeView()
        case .profile(let userId): 
            ProfileView(userId: userId)
        case .settings: 
            SettingsView()
        case .detail(let itemId): 
            DetailView(itemId: itemId)
        }
    }

    @ViewBuilder
    private func sheetView(for destination: AppCoordinator.SheetDestination) -> some View {
        switch destination {
        case .settings: 
            SettingsView()
        case .profile(let userId): 
            ProfileView(userId: userId)
        }
    }
}

struct SheetItem: Identifiable {
    let id = UUID()
    let destination: AppCoordinator.SheetDestination
}
