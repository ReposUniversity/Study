//
//  UsersViewModel.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    var networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func loadUsers() {
        isLoading = true
        errorMessage = nil
        
        networkService.requestWithRetry(.getUsers(), responseType: [User].self)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.users = response
                }
            )
            .store(in: &cancellables)
    }
    
    func createUser(name: String, email: String) {
        isLoading = true
        errorMessage = nil
        
        networkService.requestWithRetry(
            .createUser(name: name, email: email),
            responseType: User.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] newUser in
                self?.users.append(newUser)
            }
        )
        .store(in: &cancellables)
    }
    
    func deleteUser(_ user: User) {
        isLoading = true
        errorMessage = nil
        
        networkService.request(.deleteUser(id: user.id), responseType: EmptyResponse.self)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.users.removeAll { $0.id == user.id }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: NetworkError) {
        errorMessage = error.localizedDescription
        showErrorAlert = true
    }
}