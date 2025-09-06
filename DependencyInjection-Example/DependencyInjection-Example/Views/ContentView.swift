//
//  ContentView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.userService) private var userService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "person.crop.circle")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))
                
                Text("Dependency Injection Example")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    Text("Service Type:")
                        .font(.headline)
                    
                    Text("\(type(of: userService))")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Environment-based injection example
                UserView(userService: userService)
                
                Spacer()
            }
            .padding()
            .navigationTitle("DI Demo")
        }
    }
}

#Preview("With Mock Service") {
    ContentView()
        .environment(\.userService, MockUserService())
}

#Preview("With Real Service") {
    ContentView()
        .environment(\.userService, RealUserService(networkService: RealNetworkService()))
}
