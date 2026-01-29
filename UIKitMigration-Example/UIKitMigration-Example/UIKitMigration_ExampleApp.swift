//
//  UIKitMigration_ExampleApp.swift
//  UIKitMigration-Example
//
//  Main App Entry Point with Dependency Injection
//

import SwiftUI
import Combine

@main
struct UIKitMigration_ExampleApp: App {
    @StateObject private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView(container: appContainer)
        }
    }
}

// MARK: - App Container (Dependency Injection)
@MainActor
final class AppContainer: ObservableObject {
    // Infrastructure Services
    let featureToggle: FeatureToggleService
    let analytics: AnalyticsService
    let crashReporting: CrashReportingService

    // Data Layer
    let userRepository: UserRepository

    // Domain Layer
    let userUseCase: UserUseCase

    // Migration Layer
    let migrationCoordinator: MigrationCoordinator
    let riskManager: MigrationRiskManager

    // Routers
    let legacyRouter: LegacyRouter
    let modernRouter: ModernRouter

    init() {
        // Initialize Services
        self.featureToggle = FeatureToggleServiceImpl(userId: "demo-user")
        self.analytics = AnalyticsServiceImpl()
        self.crashReporting = CrashReportingServiceImpl()

        // Initialize Data Layer
        self.userRepository = UserRepositoryImpl()

        // Initialize Domain Layer
        self.userUseCase = UserUseCase(repository: userRepository)

        // Initialize Routers
        self.legacyRouter = LegacyRouterImpl(userRepository: userRepository)
        self.modernRouter = ModernRouterImpl(userUseCase: userUseCase)

        // Initialize Migration Components
        self.migrationCoordinator = MigrationCoordinator(
            featureToggle: featureToggle,
            legacyRouter: legacyRouter,
            modernRouter: modernRouter
        )

        self.riskManager = MigrationRiskManager(
            featureToggle: featureToggle,
            analytics: analytics,
            crashReporting: crashReporting
        )

        // Setup initial configuration
        setupInitialConfiguration()
    }

    private func setupInitialConfiguration() {
        // Enable some features by default for demo
        featureToggle.enableForPercentage(.userProfile, percentage: 100)
        featureToggle.enableForPercentage(.settingsScreen, percentage: 50)

        print("✅ [App] Container initialized with Clean Architecture")
        print("📊 [App] Feature Toggles configured")
        print("🔄 [App] Migration Coordinator ready")
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @ObservedObject var container: AppContainer

    var body: some View {
        TabView {
            // Demo Tab
            NavigationView {
                DemoView(container: container)
            }
            .tabItem {
                Label("Demo", systemImage: "app.fill")
            }

            // Dashboard Tab
            NavigationView {
                MigrationDashboardView(
                    riskManager: container.riskManager,
                    coordinator: container.migrationCoordinator
                )
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }

            // Info Tab
            NavigationView {
                InfoView()
            }
            .tabItem {
                Label("Info", systemImage: "info.circle.fill")
            }
        }
    }
}

// MARK: - Demo View
struct DemoView: View {
    @ObservedObject var container: AppContainer
    @State private var selectedFeature: FeatureFlag = .userProfile

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("SwiftUI Migration Example")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Based on Clean Architecture")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            // Feature Picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Select a Feature")
                    .font(.headline)

                Picker("Feature", selection: $selectedFeature) {
                    ForEach(FeatureFlag.allCases, id: \.self) { feature in
                        Text(feature.displayName).tag(feature)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // Status Card
            StatusCard(
                feature: selectedFeature,
                coordinator: container.migrationCoordinator,
                featureToggle: container.featureToggle
            )

            // Action Button
            NavigationLink {
                FeatureHostView(
                    feature: selectedFeature,
                    container: container
                )
            } label: {
                Text("Open \(selectedFeature.displayName)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Demo")
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let feature: FeatureFlag
    @ObservedObject var coordinator: MigrationCoordinator
    let featureToggle: FeatureToggleService

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Status")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            Divider()

            VStack(spacing: 8) {
                InfoRow(title: "Toggle", value: featureToggle.isEnabled(feature) ? "Enabled" : "Disabled")
                InfoRow(title: "Migrated", value: coordinator.migratedFeatures.contains(feature) ? "Yes" : "No")
                InfoRow(title: "Will Use", value: coordinator.shouldUseLegacy(feature: feature) ? "Legacy UIKit" : "Modern SwiftUI")
                InfoRow(title: "Complexity", value: feature.migrationComplexity.estimatedDays.description + " days")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var statusBadge: some View {
        Text(coordinator.shouldUseLegacy(feature: feature) ? "🏛️ Legacy" : "✨ Modern")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                coordinator.shouldUseLegacy(feature: feature) ?
                Color.orange.opacity(0.2) : Color.blue.opacity(0.2)
            )
            .cornerRadius(8)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Feature Host View
struct FeatureHostView: View {
    let feature: FeatureFlag
    let container: AppContainer

    var body: some View {
        FeatureViewControllerRepresentable(
            feature: feature,
            coordinator: container.migrationCoordinator
        )
        .navigationTitle(feature.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UIViewController Representable
struct FeatureViewControllerRepresentable: UIViewControllerRepresentable {
    let feature: FeatureFlag
    let coordinator: MigrationCoordinator

    func makeUIViewController(context: Context) -> UIViewController {
        let navigationContext = NavigationContext()
        return coordinator.routeToFeature(feature, context: navigationContext)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Info View
struct InfoView: View {
    var body: some View {
        List {
            Section("About") {
                Text("This app demonstrates the Strangler Pattern for migrating UIKit to SwiftUI using Clean Architecture.")
                    .font(.body)
            }

            Section("Architecture Layers") {
                InfoItem(
                    icon: "cube.fill",
                    title: "Domain Layer",
                    description: "Entities, Use Cases, Protocols"
                )
                InfoItem(
                    icon: "database.fill",
                    title: "Data Layer",
                    description: "Repositories, Data Sources"
                )
                InfoItem(
                    icon: "network",
                    title: "Infrastructure",
                    description: "Services (Analytics, Feature Toggles)"
                )
                InfoItem(
                    icon: "arrow.triangle.branch",
                    title: "Migration Layer",
                    description: "Coordinator, Risk Manager, Routers"
                )
                InfoItem(
                    icon: "rectangle.3.group.fill",
                    title: "Presentation",
                    description: "Legacy UIKit & Modern SwiftUI"
                )
            }

            Section("Key Features") {
                Text("• Strangler Pattern for gradual migration")
                Text("• Feature flags for controlled rollout")
                Text("• Health monitoring and rollback")
                Text("• Clean separation of concerns")
                Text("• Testable architecture")
            }
        }
        .navigationTitle("Info")
    }
}

// MARK: - Info Item
struct InfoItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
