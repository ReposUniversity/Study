//
//  UserView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct UserView: View {
    @StateObject private var viewModel: UserViewModel

    init(userService: UserServiceProtocol) {
        _viewModel = StateObject(wrappedValue: UserViewModel(userService: userService))
    }

    var body: some View {
        VStack(spacing: 20) {
            if let user = viewModel.user {
                VStack(spacing: 8) {
                    Text("Name: \(user.name)")
                        .font(.headline)
                    Text("Email: \(user.email)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("ID: \(user.id.uuidString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else if viewModel.isLoading {
                ProgressView("Loading...")
            } else {
                Text("No user loaded")
                    .foregroundColor(.secondary)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack(spacing: 16) {
                Button("Load User") {
                    viewModel.loadUser()
                }
                .disabled(viewModel.isLoading)
                
                Button("Save User") {
                    viewModel.saveUser()
                }
                .disabled(viewModel.isLoading || viewModel.user == nil)
            }
        }
        .padding()
    }
}
