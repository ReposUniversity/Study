//
//  ErrorViews.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

// MARK: - Stale Data Banner
struct StaleDataBanner: View {
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text("Data may be outdated")
                .font(.subheadline)
            Spacer()
            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: DataFlowError
    let canRetry: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text(error.userMessage)
                .multilineTextAlignment(.center)
                .font(.body)

            if canRetry {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Simple Error View
struct ErrorView: View {
    let error: UserError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let message: String
    let systemImage: String
    let action: (() -> Void)?

    init(
        message: String,
        systemImage: String = "tray",
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if let action = action {
                Button("Reload") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
