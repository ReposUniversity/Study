//
//  UserViewModel.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(userService: UserServiceProtocol = DIContainer.shared.resolve(UserServiceProtocol.self) ?? MockUserService()) {
        self.userService = userService
    }

    func loadUser() {
        isLoading = true
        errorMessage = nil

        userService.loadUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                }
            )
            .store(in: &cancellables)
    }
    
    func saveUser() {
        guard let user else { return }
        
        isLoading = true
        errorMessage = nil

        userService.saveUser(user)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] savedUser in
                    self?.user = savedUser
                }
            )
            .store(in: &cancellables)
    }
}
