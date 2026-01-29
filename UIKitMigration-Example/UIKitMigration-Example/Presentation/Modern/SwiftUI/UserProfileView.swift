//
//  UserProfileView.swift
//  UIKitMigration-Example
//
//  Presentation Layer - Modern SwiftUI View
//

import SwiftUI
import Combine

// MARK: - User Profile View (Modern SwiftUI)

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel

    init(userUseCase: UserUseCase) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userUseCase: userUseCase))
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading users...")
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    Task {
                        await viewModel.loadUsers()
                    }
                }
            } else {
                usersList
            }
        }
        .navigationTitle("User Profile (Modern)")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("✨ MODERN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }

    private var usersList: some View {
        List(viewModel.users) { user in
            UserRowView(user: user)
                .onTapGesture {
                    print("Selected user: \(user.name)")
                }
        }
        .refreshable {
            await viewModel.loadUsers()
        }
    }
}

// MARK: - User Row View

struct UserRowView: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: user.profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let lastLogin = user.lastLoginDate {
                    Text("Last login: \(lastLogin, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(user.isActive ? Color.green : Color.red)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Error")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onRetry) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - View Model

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let userUseCase: UserUseCase

    init(userUseCase: UserUseCase) {
        self.userUseCase = userUseCase
    }

    func loadUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            users = try await userUseCase.fetchUsers()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        UserProfileView(
            userUseCase: UserUseCase(
                repository: UserRepositoryImpl()
            )
        )
    }
}
