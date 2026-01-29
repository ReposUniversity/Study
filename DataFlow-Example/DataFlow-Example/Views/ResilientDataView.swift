//
//  ResilientDataView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI
import Combine

struct ResilientDataView<T, Content: View>: View {
    @StateObject private var dataManager: ResilientDataFlowManager<T>
    let content: (T) -> Content

    init(
        cacheKey: String,
        dataSource: @escaping () -> AnyPublisher<T, Error>,
        fallbackDataSource: (() -> AnyPublisher<T, Error>)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        _dataManager = StateObject(wrappedValue: ResilientDataFlowManager(
            cacheKey: cacheKey,
            dataSource: dataSource,
            fallbackDataSource: fallbackDataSource
        ))
        self.content = content
    }

    var body: some View {
        Group {
            if let data = dataManager.result.data {
                VStack(spacing: 0) {
                    if dataManager.result.hasStaleData {
                        StaleDataBanner {
                            dataManager.refresh(force: true)
                        }
                    }

                    content(data)
                }
            } else if dataManager.result.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = dataManager.result.error {
                ErrorStateView(
                    error: error,
                    canRetry: error.isRecoverable
                ) {
                    dataManager.retryIfPossible()
                }
            } else {
                EmptyStateView(
                    message: "No data available",
                    systemImage: "tray"
                )
            }
        }
        .onAppear {
            if dataManager.result.data == nil {
                dataManager.refresh()
            }
        }
    }
}
