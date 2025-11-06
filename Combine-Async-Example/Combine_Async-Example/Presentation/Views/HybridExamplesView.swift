//
//  HybridExamplesView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

/// Main hub for navigating to different Hybrid Combine + Async/Await examples
struct HybridExamplesView: View {

    var body: some View {
        NavigationStack {
            List {
                Section {
                    exampleRow(
                        title: "Hybrid Users",
                        icon: "person.2.fill",
                        color: .blue,
                        description: "Reactive search with debouncing + async loading"
                    ) {
                        HybridUsersView()
                    }

                    exampleRow(
                        title: "Reactive Streams",
                        icon: "wave.3.right",
                        color: .green,
                        description: "Merge WebSocket, API & cache with auto-reconnect"
                    ) {
                        ReactiveStreamView()
                    }

                    exampleRow(
                        title: "Structured Processing",
                        icon: "gearshape.2.fill",
                        color: .orange,
                        description: "Task groups with progress + backpressure control"
                    ) {
                        StructuredProcessingView()
                    }
                } header: {
                    Text("Examples")
                } footer: {
                    footerText
                }
            }
            .navigationTitle("Hybrid ViewModels")
        }
    }

    // MARK: - View Components

    private func exampleRow<Destination: View>(
        title: String,
        icon: String,
        color: Color,
        description: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var footerText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hybrid ViewModels with Combine and Swift Concurrency")
                .font(.caption)
                .fontWeight(.semibold)

            Text("These examples demonstrate practical patterns for bridging Combine with async/await:")
                .font(.caption)

            VStack(alignment: .leading, spacing: 6) {
                bulletPoint("Use Combine for reactive UI events (search, debouncing)")
                bulletPoint("Use async/await for discrete operations (load, sync)")
                bulletPoint("Convert at boundaries to keep code clean")
                bulletPoint("Always handle cancellation properly")
            }
            .font(.caption)

            Text("Based on the Medium article by building a practical playbook for responsive and testable SwiftUI features.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    HybridExamplesView()
}
