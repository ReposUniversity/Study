//
//  MigrationTests.swift
//  UIKitMigration-ExampleTests
//
//  Test Suite for Migration Pattern
//

import XCTest
import Combine
@testable import UIKitMigration_Example

// MARK: - Migration Test Suite

final class MigrationTests: XCTestCase {
    var migrationCoordinator: MigrationCoordinator!
    var mockFeatureToggle: MockFeatureToggleService!
    var mockAnalytics: MockAnalyticsService!
    var mockCrashReporting: MockCrashReportingService!
    var cancellables: Set<AnyCancellable>!

    @MainActor
    override func setUp() {
        super.setUp()
        mockFeatureToggle = MockFeatureToggleService()
        mockAnalytics = MockAnalyticsService()
        mockCrashReporting = MockCrashReportingService()

        let mockRepository = MockUserRepository()
        let legacyRouter = LegacyRouterImpl(userRepository: mockRepository)
        let modernRouter = ModernRouterImpl(userUseCase: UserUseCase(repository: mockRepository))

        migrationCoordinator = MigrationCoordinator(
            featureToggle: mockFeatureToggle,
            legacyRouter: legacyRouter,
            modernRouter: modernRouter
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables?.removeAll()
        migrationCoordinator = nil
        mockFeatureToggle = nil
        mockAnalytics = nil
        mockCrashReporting = nil
        super.tearDown()
    }

    // MARK: - Coordinator Tests
    @MainActor
    func testInitialState() {
        XCTAssertEqual(migrationCoordinator.migratedFeatures.count, 0)
        XCTAssertEqual(migrationCoordinator.migrationProgress, 0.0)
    }

    func testMarkFeatureAsMigrated() async {
        // Given
        let feature = FeatureFlag.userProfile

        // When
        await migrationCoordinator.markFeatureAsMigrated(feature)

        // Then
        await MainActor.run {
            XCTAssertTrue(migrationCoordinator.migratedFeatures.contains(feature))
            XCTAssertGreaterThan(migrationCoordinator.migrationProgress, 0.0)
        }
    }

    func testRollbackFeature() async {
        // Given
        let feature = FeatureFlag.userProfile
        await migrationCoordinator.markFeatureAsMigrated(feature)

        // When
        await migrationCoordinator.rollbackFeature(feature)

        // Then
        await MainActor.run {
            XCTAssertFalse(migrationCoordinator.migratedFeatures.contains(feature))
        }
    }

    func testShouldUseLegacyWhenToggleDisabled() async {
        // Given
        let feature = FeatureFlag.settingsScreen
        mockFeatureToggle.setEnabled(feature, false)

        // When
        let shouldUseLegacy = await migrationCoordinator.shouldUseLegacy(feature: feature)

        // Then
        XCTAssertTrue(shouldUseLegacy)
    }

    func testShouldUseModernWhenToggleEnabledAndMigrated() async {
        // Given
        let feature = FeatureFlag.settingsScreen
        mockFeatureToggle.setEnabled(feature, true)
        await migrationCoordinator.markFeatureAsMigrated(feature)

        // When
        let shouldUseLegacy = await migrationCoordinator.shouldUseLegacy(feature: feature)

        // Then
        XCTAssertFalse(shouldUseLegacy)
    }

    func testMigrationProgress() async {
        // Given
        let totalFeatures = FeatureFlag.allCases.count
        let halfFeatures = Array(FeatureFlag.allCases.prefix(totalFeatures / 2))

        // When
        for feature in halfFeatures {
            await migrationCoordinator.markFeatureAsMigrated(feature)
        }

        // Then
        await MainActor.run {
            let expectedProgress = Double(halfFeatures.count) / Double(totalFeatures)
            XCTAssertEqual(
                migrationCoordinator.migrationProgress,
                expectedProgress,
                accuracy: 0.01
            )
        }
    }

    func testCompletesMigrationWhenAllFeaturesMigrated() async {
        // When
        for feature in FeatureFlag.allCases {
            await migrationCoordinator.markFeatureAsMigrated(feature)
        }

        // Then
        await MainActor.run {
            XCTAssertEqual(migrationCoordinator.migrationProgress, 1.0)
        }
    }

    // MARK: - Risk Manager Tests
    func testRiskManagerStartMigration() async {
        // Given
        let riskManager = await MigrationRiskManager(
            featureToggle: mockFeatureToggle,
            analytics: mockAnalytics,
            crashReporting: mockCrashReporting
        )
        let feature = FeatureFlag.userProfile

        // When
        await riskManager.startMigration(feature: feature, rolloutPercentage: 10.0)

        // Then
        await MainActor.run {
            XCTAssertEqual(riskManager.activeMigrations.count, 1)
            XCTAssertEqual(riskManager.activeMigrations.first?.feature, feature)
            XCTAssertEqual(riskManager.activeMigrations.first?.phase, .canary)
        }
    }

    func testRiskManagerRollback() async {
        // Given
        let riskManager = await MigrationRiskManager(
            featureToggle: mockFeatureToggle,
            analytics: mockAnalytics,
            crashReporting: mockCrashReporting
        )
        let feature = FeatureFlag.userProfile
        await riskManager.startMigration(feature: feature)

        // When
        await riskManager.rollbackFeature(feature, reason: "Test rollback")

        // Then
        await MainActor.run {
            XCTAssertEqual(riskManager.rollbackQueue.count, 1)
            XCTAssertEqual(riskManager.rollbackQueue.first?.feature, feature)
            XCTAssertFalse(mockFeatureToggle.isEnabled(feature))
        }
    }

    // MARK: - Repository Tests
    func testUserRepositoryFetchUsers() async throws {
        // Given
        let repository = UserRepositoryImpl()

        // When
        let users = try await repository.fetchUsers()

        // Then
        XCTAssertFalse(users.isEmpty)
        XCTAssertTrue(users.allSatisfy { !$0.name.isEmpty })
    }

    func testUserRepositoryUpdateUser() async throws {
        // Given
        let repository = UserRepositoryImpl()
        let users = try await repository.fetchUsers()
        var user = users[0]
        user = User(
            id: user.id,
            name: "Updated Name",
            email: user.email,
            profileImageURL: user.profileImageURL,
            isActive: user.isActive,
            lastLoginDate: user.lastLoginDate
        )

        // When
        try await repository.updateUser(user)

        // Then - No error thrown
        XCTAssertTrue(true)
    }
}

// MARK: - Mock Feature Toggle Service
final class MockFeatureToggleService: FeatureToggleService {
    private var features: [FeatureFlag: Bool] = [:]
    private var percentages: [FeatureFlag: Double] = [:]

    func enableForPercentage(_ feature: FeatureFlag, percentage: Double) {
        features[feature] = true
        percentages[feature] = percentage
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

    func setEnabled(_ feature: FeatureFlag, _ enabled: Bool) {
        features[feature] = enabled
    }
}

// MARK: - Mock Analytics Service
final class MockAnalyticsService: AnalyticsService {
    var trackedEvents: [(String, [String: Any])] = []

    func track(_ event: String, properties: [String: Any]) {
        trackedEvents.append((event, properties))
    }

    func getCrashRate(for feature: FeatureFlag, timeWindow: TimeInterval) -> Double {
        return 0.0 // No crashes in tests
    }

    func getErrorRate(for feature: FeatureFlag, timeWindow: TimeInterval) -> Double {
        return 0.0 // No errors in tests
    }

    func getAverageResponseTime(for feature: FeatureFlag, timeWindow: TimeInterval) -> TimeInterval {
        return 500 // 500ms response time
    }

    func getMemoryUsage(for feature: FeatureFlag) -> Int64 {
        return 50 * 1024 * 1024 // 50MB
    }

    func getTestMetrics(testId: String) -> [TestMetric] {
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
}

// MARK: - Mock Crash Reporting Service
final class MockCrashReportingService: CrashReportingService {
    var onCrashDetected: ((CrashInfo) -> Void)?
    var crashes: [CrashInfo] = []

    func reportCrash(_ crashInfo: CrashInfo) {
        crashes.append(crashInfo)
        onCrashDetected?(crashInfo)
    }

    func reportError(_ error: Error, context: [String: Any]) {
        // Mock implementation
    }
}

// MARK: - Mock User Repository
final class MockUserRepository: UserRepository {
    private var users: [User] = [
        User(id: "1", name: "Test User 1", email: "test1@example.com"),
        User(id: "2", name: "Test User 2", email: "test2@example.com")
    ]

    func fetchUsers() async throws -> [User] {
        return users
    }

    func fetchUser(id: String) async throws -> User? {
        return users.first { $0.id == id }
    }

    func updateUser(_ user: User) async throws {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
    }

    func deleteUser(id: String) async throws {
        users.removeAll { $0.id == id }
    }

    func getCurrentUser() async -> User? {
        return users.first
    }
}
