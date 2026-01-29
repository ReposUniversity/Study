//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    let userId: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("User ID: \(userId)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Go to Settings") {
                coordinator.push(.settings)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
