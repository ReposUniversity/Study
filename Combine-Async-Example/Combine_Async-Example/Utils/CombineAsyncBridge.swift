//
//  CombineAsyncBridge.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import Foundation
import Combine

// MARK: - Publisher to Async Extensions

extension Publisher where Failure == Never {
    /// Converts a Publisher with Never failure to an async value
    /// Waits for the first element from the stream and returns it
    var asyncValue: Output {
        get async {
            await withCheckedContinuation { continuation in
                var cancellable: AnyCancellable?
                cancellable = first()
                    .sink { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
            }
        }
    }
}

extension Publisher {
    /// Converts a potentially failing Publisher into an async Result
    /// for explicit error handling
    var asyncResult: Result<Output, Failure> {
        get async {
            await withCheckedContinuation { continuation in
                var cancellable: AnyCancellable?
                cancellable = sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break // Value already sent
                        case .failure(let error):
                            continuation.resume(returning: .failure(error))
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: .success(value))
                    }
                )
            }
        }
    }

    /// Converts a Publisher to an async throwing function
    /// Provides ergonomic try await surface
    func asyncThrows() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
        }
    }
}

// MARK: - Async to Publisher Conversion

/// Wraps an async function in a Future/Publisher
/// Perfect for exposing async work to Combine-based consumers
func asyncToPublisher<T>(
    _ asyncFunction: @escaping () async throws -> T
) -> AnyPublisher<T, Error> {
    Future { promise in
        Task {
            do {
                let result = try await asyncFunction()
                promise(.success(result))
            } catch {
                promise(.failure(error))
            }
        }
    }
    .eraseToAnyPublisher()
}

// MARK: - AsyncSequence to Publisher Bridge

/// Bridge AsyncSequence to Combine Publisher
struct AsyncPublisher<Element>: Publisher {
    typealias Output = Element
    typealias Failure = Never

    private let sequence: () -> AsyncStream<Element>

    init(_ sequence: @escaping () -> AsyncStream<Element>) {
        self.sequence = sequence
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = AsyncSubscription(
            subscriber: subscriber,
            sequence: sequence()
        )
        subscriber.receive(subscription: subscription)
    }
}

/// Subscription that bridges AsyncStream to Combine
class AsyncSubscription<S: Subscriber>: Subscription where S.Input: Sendable, S.Failure == Never {
    private var subscriber: S?
    private var task: Task<Void, Never>?

    init(subscriber: S, sequence: AsyncStream<S.Input>) {
        self.subscriber = subscriber

        task = Task {
            for await value in sequence {
                guard !Task.isCancelled else { break }

                let demand = subscriber.receive(value)
                if demand == .none {
                    break
                }
            }

            subscriber.receive(completion: .finished)
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // Async sequences handle backpressure automatically
    }

    func cancel() {
        task?.cancel()
        subscriber = nil
    }
}
