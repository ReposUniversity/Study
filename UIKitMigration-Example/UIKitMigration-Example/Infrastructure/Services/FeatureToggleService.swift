//
//  FeatureToggleService.swift
//  UIKitMigration-Example
//
//  Infrastructure Layer - Feature Toggle Service
//

import Foundation

// MARK: - Feature Toggle Service Protocol

protocol FeatureToggleService {
    func enableForPercentage(_ feature: FeatureFlag, percentage: Double)
    func disable(_ feature: FeatureFlag)
    func isEnabled(_ feature: FeatureFlag) -> Bool
    func getRolloutPercentage(_ feature: FeatureFlag) -> Double
}

// MARK: - Feature Toggle Service Implementation

final class FeatureToggleServiceImpl: FeatureToggleService {
    private var features: [FeatureFlag: Bool] = [:]
    private var percentages: [FeatureFlag: Double] = [:]
    private let userId: String

    init(userId: String = "default-user") {
        self.userId = userId
    }

    func enableForPercentage(_ feature: FeatureFlag, percentage: Double) {
        percentages[feature] = percentage

        // Use consistent hashing for user bucketing
        let hash = "\(feature.rawValue)_\(userId)".hashValue
        let normalizedHash = abs(Double(hash)) / Double(Int.max)
        let isInPercentile = normalizedHash < (percentage / 100.0)

        features[feature] = isInPercentile
    }

    func disable(_ feature: FeatureFlag) {
        features[feature] = false
        percentages[feature] = 0.0
    }

    func isEnabled(_ feature: FeatureFlag) -> Bool {
        return features[feature] ?? false
    }

    func getRolloutPercentage(_ feature: FeatureFlag) -> Double {
        return percentages[feature] ?? 0.0
    }
}
