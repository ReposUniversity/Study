//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Home")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button("Go to Profile") {
                    coordinator.push(.profile(userId: "user123"))
                }
                .buttonStyle(.borderedProminent)
                
                Button("Open Settings") {
                    coordinator.presentSheet(.settings)
                }
                .buttonStyle(.bordered)
                
                Button("View Detail") {
                    coordinator.push(.detail(itemId: UUID()))
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("Home")
    }
}
