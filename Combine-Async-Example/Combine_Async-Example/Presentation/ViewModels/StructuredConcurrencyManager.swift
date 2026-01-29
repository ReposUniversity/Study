//
//  StructuredConcurrencyManager.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

/// Demonstrates structured concurrency with Combine
/// - Task groups for parallel processing
/// - Progress tracking
/// - Backpressure handling
/// - Proper cancellation
@MainActor
class StructuredConcurrencyManager: ObservableObject {

    // MARK: - Published Properties

    @Published var results: [ProcessingResult] = []
    @Published var progress: Double = 0.0
    @Published var isProcessing = false

    // MARK: - Private Properties

    private var processingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Structured Concurrency Processing

    /// Process multiple items with structured concurrency using task groups
    /// Demonstrates parallel processing with progress tracking
    func processItems(_ items: [ProcessingItem]) {
        processingTask?.cancel()

        processingTask = Task {
            isProcessing = true
            progress = 0.0
            results = []

            await withTaskGroup(of: ProcessingResult?.self) { group in
                for (index, item) in items.enumerated() {
                    group.addTask {
                        await self.processItem(item, index: index)
                    }
                }

                var completedCount = 0
                for await result in group {
                    guard !Task.isCancelled else { break }

                    if let result = result {
                        results.append(result)
                    }

                    completedCount += 1
                    progress = Double(completedCount) / Double(items.count)
                }
            }

            if !Task.isCancelled {
                isProcessing = false
            }
        }
    }

    /// Process a single item with simulated work
    private func processItem(_ item: ProcessingItem, index: Int) async -> ProcessingResult? {
        let startTime = Date()

        do {
            // Simulate async processing with random delay
            let delay = UInt64.random(in: 500_000_000...2_000_000_000)
            try await Task.sleep(nanoseconds: delay)

            guard !Task.isCancelled else { return nil }

            let processingTime = Date().timeIntervalSince(startTime)

            return ProcessingResult(
                itemId: item.id,
                status: .completed,
                data: "Processed: \(item.name)",
                processingTime: processingTime
            )
        } catch {
            guard !Task.isCancelled else { return nil }

            return ProcessingResult(
                itemId: item.id,
                status: .failed,
                data: error.localizedDescription,
                processingTime: 0
            )
        }
    }

    // MARK: - AsyncStream to Publisher Bridge

    /// Stream processing updates as a Publisher
    /// Demonstrates bridging AsyncStream to Combine
    func streamProcessingUpdates() -> AnyPublisher<ProcessingUpdate, Never> {
        AsyncPublisher {
            self.createProcessingStream()
        }
        .eraseToAnyPublisher()
    }

    /// Create an async stream of processing updates
    private func createProcessingStream() -> AsyncStream<ProcessingUpdate> {
        AsyncStream { continuation in
            let task = Task {
                for i in 1...100 {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

                    guard !Task.isCancelled else { break }

                    let update = ProcessingUpdate(
                        step: i,
                        message: "Processing step \(i)",
                        timestamp: Date()
                    )

                    continuation.yield(update)
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Backpressure Processing

    /// Process with backpressure using Combine's flatMap
    /// Demonstrates controlled concurrency with max concurrent tasks
    func processWithBackpressure(_ items: [ProcessingItem]) {
        isProcessing = true
        progress = 0.0
        results = []

        let itemPublisher = items.publisher
        let maxConcurrentTasks = 3

        itemPublisher
            .flatMap(maxPublishers: .max(maxConcurrentTasks)) { item in
                Future { promise in
                    Task {
                        let result = await self.processItem(item, index: 0)
                        promise(.success(result))
                    }
                }
            }
            .compactMap { $0 }
            .collect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.results = results
                self?.isProcessing = false
                self?.progress = 1.0
            }
            .store(in: &cancellables)
    }

    // MARK: - Cancellation

    /// Cancel ongoing processing
    func cancelProcessing() {
        processingTask?.cancel()
        isProcessing = false
    }

    // MARK: - Cleanup

    deinit {
        processingTask?.cancel()
        cancellables.removeAll()
    }
}
