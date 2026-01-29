//
//  ErrorHandling.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Data Flow Result
struct DataFlowResult<T> {
    let data: T?
    let error: DataFlowError?
    let isLoading: Bool
    let lastSuccessfulUpdate: Date?

    var isSuccess: Bool { error == nil && data != nil }
    var hasStaleData: Bool {
        guard let lastUpdate = lastSuccessfulUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) > 300 // 5 minutes
    }
}

// MARK: - Data Flow Error
enum DataFlowError: Error, Equatable {
    case networkError(String)
    case parseError(String)
    case cacheError(String)
    case validationError(String)

    var isRecoverable: Bool {
        switch self {
        case .networkError: return true
        case .parseError: return false
        case .cacheError: return true
        case .validationError: return false
        }
    }

    var userMessage: String {
        switch self {
        case .networkError:
            return "Connection issue. Tap to retry."
        case .parseError:
            return "Data format error. Please try again later."
        case .cacheError:
            return "Storage issue. Data may be outdated."
        case .validationError(let message):
            return message
        }
    }
}

// MARK: - Resilient Data Flow Manager
@MainActor
class ResilientDataFlowManager<T>: ObservableObject {
    @Published private(set) var result: DataFlowResult<T>

    private let dataSource: () -> AnyPublisher<T, Error>
    private let fallbackDataSource: (() -> AnyPublisher<T, Error>)?
    private let cacheKey: String

    private var cancellables = Set<AnyCancellable>()
    private var retryAttempts = 0
    private let maxRetryAttempts = 3

    init(
        cacheKey: String,
        dataSource: @escaping () -> AnyPublisher<T, Error>,
        fallbackDataSource: (() -> AnyPublisher<T, Error>)? = nil
    ) {
        self.cacheKey = cacheKey
        self.dataSource = dataSource
        self.fallbackDataSource = fallbackDataSource

        // Initialize with cached data if available
        self.result = DataFlowResult(
            data: nil,
            error: nil,
            isLoading: false,
            lastSuccessfulUpdate: nil
        )
    }

    func refresh(force: Bool = false) {
        guard !result.isLoading || force else { return }

        result = DataFlowResult(
            data: result.data,
            error: nil,
            isLoading: true,
            lastSuccessfulUpdate: result.lastSuccessfulUpdate
        )

        dataSource()
            .retry(maxRetryAttempts)
            .catch { [weak self] error -> AnyPublisher<T, Error> in
                // Try fallback data source if available
                if let fallback = self?.fallbackDataSource {
                    return fallback()
                        .catch { _ in
                            Fail(error: error)
                        }
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] data in
                    self?.handleSuccess(data)
                }
            )
            .store(in: &cancellables)
    }

    func retryIfPossible() {
        guard let error = result.error, error.isRecoverable else { return }

        if retryAttempts < maxRetryAttempts {
            retryAttempts += 1
            refresh(force: true)
        }
    }

    private func handleSuccess(_ data: T) {
        retryAttempts = 0
        let now = Date()

        result = DataFlowResult(
            data: data,
            error: nil,
            isLoading: false,
            lastSuccessfulUpdate: now
        )
    }

    private func handleError(_ error: Error) {
        let dataFlowError: DataFlowError

        if let urlError = error as? URLError {
            dataFlowError = .networkError(urlError.localizedDescription)
        } else if error is DecodingError {
            dataFlowError = .parseError(error.localizedDescription)
        } else {
            dataFlowError = .networkError(error.localizedDescription)
        }

        result = DataFlowResult(
            data: result.data, // Keep existing data
            error: dataFlowError,
            isLoading: false,
            lastSuccessfulUpdate: result.lastSuccessfulUpdate
        )
    }
}
