//
//  AnalyticsService.swift
//  UIKitMigration-Example
//
//  Infrastructure Layer - Analytics Service
//

import Foundation

// MARK: - Test Metric

struct TestMetric {
    let variant: String
    let conversions: Double
    let totalUsers: Double
    let conversionRate: Double
    let averageValue: Double
}

// MARK: - Analytics Service Protocol

protocol AnalyticsService {
    func track(_ event: String, properties: [String: Any])
    func getCrashRate(for feature: FeatureFlag, timeWindow: TimeInterval) -> Double
    func getErrorRate(for feature: FeatureFlag, timeWindow: TimeInterval) -> Double
    func getAverageResponseTime(for feature: FeatureFlag, timeWindow: TimeInterval) -> TimeInterval
    func getMemoryUsage(for feature: FeatureFlag) -> Int64
    func getTestMetrics(testId: String) -> [TestMetric]
}

// MARK: - Analytics Service Implementation

final class AnalyticsServiceImpl: AnalyticsService {
    private var trackedEvents: [(String, [String: Any], Date)] = []
    private var crashRates: [FeatureFlag: Double] = [:]
    private var errorRates: [FeatureFlag: Double] = [:]
    private var responseTimes: [FeatureFlag: TimeInterval] = [:]
    private var memoryUsages: [FeatureFlag: Int64] = [:]

    func track(_ event: String, properties: [String: Any]) {
        trackedEvents.append((event, properties, Date()))
        print("📊 [Analytics] \(event): \(properties)")
    }

    func getCrashRate(for feature: FeatureFlag, timeWindow: TimeInterval) -> Double {
        // Simulate crash rate (in real app, would query crash reporting service)
        return crashRates[feature] ?? 0.0
    }

    func getErrorRate(for feature: FeatureFlag, timeWindow: TimeInterval) -> Double {
        // Simulate error rate
        return errorRates[feature] ?? 0.0
    }

    func getAverageResponseTime(for feature: FeatureFlag, timeWindow: TimeInterval) -> TimeInterval {
        // Simulate response time
        return responseTimes[feature] ?? 500.0 // Default 500ms
    }

    func getMemoryUsage(for feature: FeatureFlag) -> Int64 {
        // Simulate memory usage
        return memoryUsages[feature] ?? (50 * 1024 * 1024) // Default 50MB
    }

    func getTestMetrics(testId: String) -> [TestMetric] {
        // Simulate A/B test metrics
        return [
            TestMetric(
                variant: "legacy",
                conversions: 100,
                totalUsers: 1000,
                conversionRate: 0.1,
                averageValue: 25.0
            ),
            TestMetric(
                variant: "modern",
                conversions: 130,
                totalUsers: 1000,
                conversionRate: 0.13,
                averageValue: 28.0
            )
        ]
    }

    // MARK: - Helper Methods for Testing
    func setCrashRate(_ rate: Double, for feature: FeatureFlag) {
        crashRates[feature] = rate
    }

    func setErrorRate(_ rate: Double, for feature: FeatureFlag) {
        errorRates[feature] = rate
    }

    func setResponseTime(_ time: TimeInterval, for feature: FeatureFlag) {
        responseTimes[feature] = time
    }

    func setMemoryUsage(_ usage: Int64, for feature: FeatureFlag) {
        memoryUsages[feature] = usage
    }
}
