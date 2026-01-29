//
//  ContentView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.networkService) var networkServiceContainer
    @StateObject private var viewModel: UsersViewModel
    @State private var showingAddUser = false
    @State private var newUserName = ""
    @State private var newUserEmail = ""
    
    init() {
        // This will be overridden by the environment
        let mockService = MockNetworkService()
        mockService.setupUsersMock()
        self._viewModel = StateObject(wrappedValue: UsersViewModel(networkService: mockService))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.users) { user in
                            UserRowView(user: user)
                        }
                        .onDelete(perform: deleteUsers)
                    }
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add User") {
                        showingAddUser = true
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        viewModel.loadUsers()
                    }
                }
            }
            .onAppear {
                // Override the view model's network service with the environment one
                viewModel.networkService = networkServiceContainer.networkService
                viewModel.loadUsers()
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK") { }
                Button("Retry") {
                    viewModel.loadUsers()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView(
                    isPresented: $showingAddUser,
                    onAddUser: { name, email in
                        viewModel.createUser(name: name, email: email)
                    }
                )
            }
        }
    }
    
    private func deleteUsers(offsets: IndexSet) {
        for index in offsets {
            let user = viewModel.users[index]
            viewModel.deleteUser(user)
        }
    }
}

#Preview("Production") {
    ContentView()
        .environment(\.networkService, NetworkServiceContainer.production())
}

#Preview("Mock") {
    ContentView()
        .environment(\.networkService, NetworkServiceContainer.mock())
}
