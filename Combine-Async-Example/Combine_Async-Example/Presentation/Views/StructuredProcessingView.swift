//
//  StructuredProcessingView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

/// Demonstrates structured concurrency with Combine
/// - Task groups for parallel processing
/// - Progress tracking
/// - Backpressure control
struct StructuredProcessingView: View {

    @StateObject private var manager = StructuredConcurrencyManager()
    @State private var itemCount: Int = 10
    @State private var useBackpressure: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Settings section
                settingsSection

                // Processing controls
                if manager.isProcessing {
                    processingSection
                } else {
                    startButton
                }

                // Results list
                resultsList
            }
            .padding()
            .navigationTitle("Structured Processing")
        }
    }

    // MARK: - View Components

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            HStack {
                Text("Items to process:")
                Spacer()
                Stepper("\(itemCount)", value: $itemCount, in: 1...50)
                    .disabled(manager.isProcessing)
            }

            Toggle("Use backpressure (max 3 concurrent)", isOn: $useBackpressure)
                .disabled(manager.isProcessing)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    private var processingSection: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Processing")
                        .font(.headline)

                    Spacer()

                    Text("\(Int(manager.progress * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: manager.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)

                Text("\(manager.results.count) of \(itemCount) completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Cancel button
            Button(role: .destructive) {
                manager.cancelProcessing()
            } label: {
                Label("Cancel", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var startButton: some View {
        Button {
            let items = ProcessingItem.mockItems(count: itemCount)

            if useBackpressure {
                manager.processWithBackpressure(items)
            } else {
                manager.processItems(items)
            }
        } label: {
            Label("Start Processing", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !manager.results.isEmpty {
                HStack {
                    Text("Results (\(manager.results.count))")
                        .font(.headline)

                    Spacer()

                    let successCount = manager.results.filter { $0.status == .completed }.count
                    let failureCount = manager.results.filter { $0.status == .failed }.count

                    Text("\(successCount) ✓  \(failureCount) ✗")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            List(manager.results, id: \.id) { result in
                resultRow(result)
            }
            .listStyle(.plain)
        }
    }

    private func resultRow(_ result: ProcessingResult) -> some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(result.status == .completed ? Color.green : Color.red)
                .frame(width: 12, height: 12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(result.data)
                    .font(.caption)
                    .lineLimit(1)

                if result.status == .completed {
                    Text(String(format: "%.2fs", result.processingTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status badge
            Text(statusText(result.status))
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusBackgroundColor(result.status))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func statusText(_ status: ProcessingStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    private func statusBackgroundColor(_ status: ProcessingStatus) -> Color {
        switch status {
        case .pending: return Color.gray.opacity(0.2)
        case .processing: return Color.blue.opacity(0.2)
        case .completed: return Color.green.opacity(0.2)
        case .failed: return Color.red.opacity(0.2)
        }
    }
}

// MARK: - Preview

#Preview {
    StructuredProcessingView()
}
