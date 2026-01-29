//
//  HybridUsersView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

/// Demonstrates the hybrid ViewModel pattern
/// - Reactive search with Combine debouncing
/// - Async/await for loading and refreshing
/// - Proper cancellation and error handling
struct HybridUsersView: View {

    @StateObject private var viewModel: HybridUserViewModel
    @State private var selectedUser: User?
    @State private var showDetails = false

    init(userService: UserServiceProtocol = UserService()) {
        _viewModel = StateObject(wrappedValue: HybridUserViewModel(userService: userService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Error banner
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }

                // Users list
                List(viewModel.searchResults, id: \.id) { user in
                    userRow(user)
                        .onTapGesture {
                            selectedUser = user
                            showDetails = true
                        }
                }
                .searchable(
                    text: $viewModel.searchText,
                    prompt: "Search users..."
                )
                .overlay {
                    if viewModel.isLoading {
                        ProgressView("Loading users...")
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("No users found for '\(viewModel.searchText)'")
                        )
                    }
                }
            }
            .navigationTitle("Hybrid Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refreshAllData()
                        }
                    } label: {
                        Label("Refresh All", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadUsers()
            }
            .sheet(isPresented: $showDetails) {
                if let user = selectedUser {
                    UserDetailsView(user: user)
                }
            }
        }
    }

    // MARK: - View Components

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(.caption)
                .foregroundColor(.white)

            Spacer()

            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.red)
    }

    private func userRow(_ user: User) -> some View {
        HStack(spacing: 12) {
            Image(systemName: user.avatar ?? "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)

                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Details View

struct UserDetailsView: View {
    let user: User

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: user.avatar ?? "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: 8) {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HybridUsersView()
}
