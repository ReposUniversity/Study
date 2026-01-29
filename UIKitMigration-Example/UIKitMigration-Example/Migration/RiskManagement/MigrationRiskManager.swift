//
//  MigrationRiskManager.swift
//  UIKitMigration-Example
//
//  Migration Layer - Risk Management System
//

import Foundation
import Combine

// MARK: - Migration Phase

enum MigrationPhase: String, CaseIterable {
    case canary = "canary"
    case limited = "limited"
    case extended = "extended"
    case full = "full"
    case completed = "completed"
    case failed = "failed"
}

// MARK: - Migration Status

struct MigrationStatus: Identifiable {
    let id = UUID()
    let feature: FeatureFlag
    let startTime: Date
    var rolloutPercentage: Double
    var phase: MigrationPhase
    var completionTime: Date?
    var rollbackReason: String?
}

// MARK: - Rollback Operation

struct RollbackOperation: Identifiable {
    let id = UUID()
    let feature: FeatureFlag
    let reason: String
    let timestamp: Date
    var status: RollbackStatus = .pending
}

enum RollbackStatus {
    case pending
    case inProgress
    case completed
    case failed
}

// MARK: - Feature Health

struct FeatureHealth {
    let isHealthy: Bool
    let issues: [String]
    let metrics: HealthMetricsSnapshot
}

// MARK: - Health Metrics

struct HealthMetrics {
    let overallHealth: Double
    let activeMigrationCount: Int
    let completedMigrationCount: Int
    let failedMigrationCount: Int
    let lastUpdated: Date

    init(
        overallHealth: Double = 1.0,
        activeMigrationCount: Int = 0,
        completedMigrationCount: Int = 0,
        failedMigrationCount: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.overallHealth = overallHealth
        self.activeMigrationCount = activeMigrationCount
        self.completedMigrationCount = completedMigrationCount
        self.failedMigrationCount = failedMigrationCount
        self.lastUpdated = lastUpdated
    }
}

struct HealthMetricsSnapshot {
    let crashRate: Double
    let errorRate: Double
    let avgResponseTime: TimeInterval
    let memoryUsage: Int64
}

// MARK: - Migration Risk Manager

@MainActor
final class MigrationRiskManager: ObservableObject {
    @Published var activeMigrations: [MigrationStatus] = []
    @Published var rollbackQueue: [RollbackOperation] = []
    @Published var healthMetrics: HealthMetrics = HealthMetrics()

    private let featureToggle: FeatureToggleService
    private let analytics: AnalyticsService
    private var crashReporting: CrashReportingService

    private var healthTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(
        featureToggle: FeatureToggleService,
        analytics: AnalyticsService,
        crashReporting: CrashReportingService
    ) {
        self.featureToggle = featureToggle
        self.analytics = analytics
        self.crashReporting = crashReporting

        setupHealthMonitoring()
        setupCrashHandling()
    }

    // MARK: - Setup
    private func setupHealthMonitoring() {
        healthTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectHealthMetrics()
            }
        }
    }

    private func setupCrashHandling() {
        crashReporting.onCrashDetected = { [weak self] crashInfo in
            Task { @MainActor in
                self?.handleCrashInMigratedFeature(crashInfo)
            }
        }
    }

    // MARK: - Migration Lifecycle
    func startMigration(
        feature: FeatureFlag,
        rolloutPercentage: Double = 10.0
    ) {
        let migration = MigrationStatus(
            feature: feature,
            startTime: Date(),
            rolloutPercentage: rolloutPercentage,
            phase: .canary
        )

        activeMigrations.append(migration)

        // Enable feature for percentage of users
        featureToggle.enableForPercentage(feature, percentage: rolloutPercentage)

        // Track migration start
        analytics.track("migration_started", properties: [
            "feature": feature.rawValue,
            "rollout_percentage": rolloutPercentage
        ])

        // Schedule automatic health check
        scheduleHealthCheck(for: feature)
    }

    private func scheduleHealthCheck(for feature: FeatureFlag) {
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds for demo
            performHealthCheck(for: feature)
        }
    }

    // MARK: - Health Checking
    private func performHealthCheck(for feature: FeatureFlag) {
        guard let migration = activeMigrations.first(where: { $0.feature == feature }) else { return }

        let health = evaluateFeatureHealth(feature)

        if health.isHealthy {
            // Proceed to next phase
            progressMigration(migration)
        } else {
            // Initiate rollback
            rollbackFeature(feature, reason: "Health check failed: \(health.issues.joined(separator: ", "))")
        }
    }

    private func evaluateFeatureHealth(_ feature: FeatureFlag) -> FeatureHealth {
        var issues: [String] = []

        // Check crash rate
        let crashRate = analytics.getCrashRate(for: feature, timeWindow: 300) // 5 minutes
        if crashRate > 0.01 { // More than 1% crash rate
            issues.append("High crash rate: \(crashRate * 100)%")
        }

        // Check error rate
        let errorRate = analytics.getErrorRate(for: feature, timeWindow: 300)
        if errorRate > 0.05 { // More than 5% error rate
            issues.append("High error rate: \(errorRate * 100)%")
        }

        // Check performance metrics
        let avgResponseTime = analytics.getAverageResponseTime(for: feature, timeWindow: 300)
        if avgResponseTime > 2000 { // More than 2 seconds
            issues.append("Slow response time: \(avgResponseTime)ms")
        }

        // Check memory usage
        let memoryUsage = analytics.getMemoryUsage(for: feature)
        if memoryUsage > 100 * 1024 * 1024 { // More than 100MB
            issues.append("High memory usage: \(memoryUsage / 1024 / 1024)MB")
        }

        return FeatureHealth(
            isHealthy: issues.isEmpty,
            issues: issues,
            metrics: HealthMetricsSnapshot(
                crashRate: crashRate,
                errorRate: errorRate,
                avgResponseTime: avgResponseTime,
                memoryUsage: memoryUsage
            )
        )
    }

    // MARK: - Migration Progression
    private func progressMigration(_ migration: MigrationStatus) {
        guard let index = activeMigrations.firstIndex(where: { $0.id == migration.id }) else { return }

        var updatedMigration = migration

        switch migration.phase {
        case .canary:
            updatedMigration.phase = .limited
            updatedMigration.rolloutPercentage = 25.0
        case .limited:
            updatedMigration.phase = .extended
            updatedMigration.rolloutPercentage = 50.0
        case .extended:
            updatedMigration.phase = .full
            updatedMigration.rolloutPercentage = 100.0
        case .full:
            updatedMigration.phase = .completed
            completeMigration(migration.feature)
            return
        case .completed, .failed:
            return
        }

        activeMigrations[index] = updatedMigration
        featureToggle.enableForPercentage(migration.feature, percentage: updatedMigration.rolloutPercentage)

        analytics.track("migration_progressed", properties: [
            "feature": migration.feature.rawValue,
            "phase": updatedMigration.phase.rawValue,
            "rollout_percentage": updatedMigration.rolloutPercentage
        ])

        // Schedule next health check
        scheduleHealthCheck(for: migration.feature)
    }

    // MARK: - Rollback
    func rollbackFeature(_ feature: FeatureFlag, reason: String) {
        // Disable the feature immediately
        featureToggle.disable(feature)

        // Update migration status
        if let index = activeMigrations.firstIndex(where: { $0.feature == feature }) {
            activeMigrations[index].phase = .failed
            activeMigrations[index].rollbackReason = reason
        }

        // Create rollback operation
        let rollback = RollbackOperation(
            feature: feature,
            reason: reason,
            timestamp: Date(),
            status: .pending
        )
        rollbackQueue.append(rollback)

        // Track rollback
        analytics.track("migration_rolled_back", properties: [
            "feature": feature.rawValue,
            "reason": reason
        ])

        // Send alert to team
        sendRollbackAlert(feature: feature, reason: reason)
    }

    private func completeMigration(_ feature: FeatureFlag) {
        if let index = activeMigrations.firstIndex(where: { $0.feature == feature }) {
            activeMigrations[index].phase = .completed
            activeMigrations[index].completionTime = Date()
        }

        analytics.track("migration_completed", properties: [
            "feature": feature.rawValue
        ])
    }

    // MARK: - Crash Handling
    private func handleCrashInMigratedFeature(_ crashInfo: CrashInfo) {
        // Check if crash is related to any migrated features
        let relatedFeatures = activeMigrations
            .filter { $0.phase != .completed && $0.phase != .failed }
            .map { $0.feature }

        for feature in relatedFeatures {
            if crashInfo.stackTrace.contains(feature.rawValue) {
                rollbackFeature(feature, reason: "Crash detected: \(crashInfo.description)")
                break
            }
        }
    }

    // MARK: - Health Metrics
    private func collectHealthMetrics() {
        let newMetrics = HealthMetrics(
            overallHealth: calculateOverallHealth(),
            activeMigrationCount: activeMigrations.filter { $0.phase != .completed && $0.phase != .failed }.count,
            completedMigrationCount: activeMigrations.filter { $0.phase == .completed }.count,
            failedMigrationCount: activeMigrations.filter { $0.phase == .failed }.count,
            lastUpdated: Date()
        )

        healthMetrics = newMetrics
    }

    private func calculateOverallHealth() -> Double {
        let totalMigrations = activeMigrations.count
        guard totalMigrations > 0 else { return 1.0 }

        let healthyMigrations = activeMigrations.filter { migration in
            let health = evaluateFeatureHealth(migration.feature)
            return health.isHealthy
        }.count

        return Double(healthyMigrations) / Double(totalMigrations)
    }

    private func sendRollbackAlert(feature: FeatureFlag, reason: String) {
        // Implementation would send alert to development team
        print("🚨 ROLLBACK ALERT: \(feature.displayName) - \(reason)")
    }

    deinit {
        healthTimer?.invalidate()
        cancellables.removeAll()
    }
}
