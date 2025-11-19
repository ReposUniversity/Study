//
//  MigrationDashboardView.swift
//  UIKitMigration-Example
//
//  Presentation Layer - Migration Dashboard (SwiftUI)
//

import SwiftUI

// MARK: - Migration Dashboard View

struct MigrationDashboardView: View {
    @ObservedObject var riskManager: MigrationRiskManager
    @ObservedObject var coordinator: MigrationCoordinator

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ProgressCard(coordinator: coordinator)

                    HealthSummaryCard(metrics: riskManager.healthMetrics)

                    ActiveMigrationsSection(migrations: riskManager.activeMigrations)

                    if !riskManager.rollbackQueue.isEmpty {
                        RollbackQueueSection(rollbacks: riskManager.rollbackQueue)
                    }

                    FeaturesListSection(
                        coordinator: coordinator,
                        riskManager: riskManager
                    )
                }
                .padding()
            }
            .navigationTitle("Migration Dashboard")
            .refreshable {
                // Refresh metrics
            }
        }
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    @ObservedObject var coordinator: MigrationCoordinator

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Migration Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(coordinator.migrationProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            ProgressView(value: coordinator.migrationProgress)
                .tint(.blue)

            HStack {
                VStack(alignment: .leading) {
                    Text("\(coordinator.migratedFeatures.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Migrated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(FeatureFlag.allCases.count - coordinator.migratedFeatures.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Health Summary Card

struct HealthSummaryCard: View {
    let metrics: HealthMetrics

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Migration Health")
                    .font(.headline)
                Spacer()
                Text("\(Int(metrics.overallHealth * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(healthColor)
            }

            ProgressView(value: metrics.overallHealth)
                .tint(healthColor)

            HStack {
                MetricItem(title: "Active", value: "\(metrics.activeMigrationCount)", color: .blue)
                Spacer()
                MetricItem(title: "Completed", value: "\(metrics.completedMigrationCount)", color: .green)
                Spacer()
                MetricItem(title: "Failed", value: "\(metrics.failedMigrationCount)", color: .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var healthColor: Color {
        if metrics.overallHealth > 0.8 {
            return .green
        } else if metrics.overallHealth > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Metric Item

struct MetricItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Active Migrations Section

struct ActiveMigrationsSection: View {
    let migrations: [MigrationStatus]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Migrations")
                .font(.headline)

            if migrations.filter({ $0.phase != .completed && $0.phase != .failed }).isEmpty {
                Text("No active migrations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(migrations.filter { $0.phase != .completed && $0.phase != .failed }) { migration in
                        MigrationRow(migration: migration)
                    }
                }
            }
        }
    }
}

// MARK: - Migration Row
struct MigrationRow: View {
    let migration: MigrationStatus

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(migration.feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(migration.phase.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(migration.rolloutPercentage))%")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Rollback Queue Section

struct RollbackQueueSection: View {
    let rollbacks: [RollbackOperation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Rollbacks")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(rollbacks.prefix(5)) { rollback in
                    RollbackRow(rollback: rollback)
                }
            }
        }
    }
}

// MARK: - Rollback Row

struct RollbackRow: View {
    let rollback: RollbackOperation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rollback.feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(rollback.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(rollback.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Features List Section

struct FeaturesListSection: View {
    @ObservedObject var coordinator: MigrationCoordinator
    @ObservedObject var riskManager: MigrationRiskManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Features")
                .font(.headline)

            LazyVStack(spacing: 8) {
                ForEach(FeatureFlag.allCases, id: \.self) { feature in
                    FeatureRow(
                        feature: feature,
                        isMigrated: coordinator.migratedFeatures.contains(feature),
                        onMigrate: {
                            coordinator.markFeatureAsMigrated(feature)
                            riskManager.startMigration(feature: feature)
                        },
                        onRollback: {
                            coordinator.rollbackFeature(feature)
                            riskManager.rollbackFeature(feature, reason: "Manual rollback")
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: FeatureFlag
    let isMigrated: Bool
    let onMigrate: () -> Void
    let onRollback: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text(feature.migrationComplexity.estimatedDays.description + " days")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 3, height: 3)

                    Text(complexityText)
                        .font(.caption2)
                        .foregroundColor(complexityColor)
                }
            }

            Spacer()

            if isMigrated {
                Button(action: onRollback) {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(.orange)
                }
                .buttonStyle(.borderless)

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: onMigrate) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(isMigrated ? Color.green.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private var complexityText: String {
        switch feature.migrationComplexity {
        case .low: return "Low complexity"
        case .medium: return "Medium complexity"
        case .high: return "High complexity"
        }
    }

    private var complexityColor: Color {
        switch feature.migrationComplexity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    MigrationDashboardView(
        riskManager: MigrationRiskManager(
            featureToggle: FeatureToggleServiceImpl(),
            analytics: AnalyticsServiceImpl(),
            crashReporting: CrashReportingServiceImpl()
        ),
        coordinator: MigrationCoordinator(
            featureToggle: FeatureToggleServiceImpl(),
            legacyRouter: LegacyRouterImpl(userRepository: UserRepositoryImpl()),
            modernRouter: ModernRouterImpl(userUseCase: UserUseCase(repository: UserRepositoryImpl()))
        )
    )
}
