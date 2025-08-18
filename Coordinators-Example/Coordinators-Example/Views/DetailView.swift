//
//  Coordinators_ExampleApp.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    let itemId: UUID
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Detail View")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Item Information")
                    .font(.headline)
                
                Text("ID: \(itemId.uuidString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("This is a detailed view showing information about the selected item.")
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button("Go to Profile") {
                coordinator.push(.profile(userId: "detail-user"))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
