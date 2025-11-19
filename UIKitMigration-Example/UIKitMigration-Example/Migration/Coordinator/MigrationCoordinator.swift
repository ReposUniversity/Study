//
//  MigrationCoordinator.swift
//  UIKitMigration-Example
//
//  Migration Layer - Central Migration Coordinator (Strangler Pattern)
//

import SwiftUI
import UIKit
import Combine

// MARK: - Migration Coordinator

@MainActor
final class MigrationCoordinator: ObservableObject {
    @Published var migratedFeatures: Set<FeatureFlag> = []
    @Published var migrationProgress: Double = 0.0

    private let featureToggle: FeatureToggleService
    private let legacyRouter: LegacyRouter
    private let modernRouter: ModernRouter

    init(
        featureToggle: FeatureToggleService,
        legacyRouter: LegacyRouter,
        modernRouter: ModernRouter
    ) {
        self.featureToggle = featureToggle
        self.legacyRouter = legacyRouter
        self.modernRouter = modernRouter

        updateMigrationProgress()
    }

    // MARK: - Core Decision Logic
    
    func shouldUseLegacy(feature: FeatureFlag) -> Bool {
        // Check feature toggle first
        if !featureToggle.isEnabled(feature) {
            return true
        }

        // Check if feature is marked as migrated
        return !migratedFeatures.contains(feature)
    }

    // MARK: - Routing
    
    func routeToFeature(_ feature: FeatureFlag, context: NavigationContext) -> UIViewController {
        if shouldUseLegacy(feature: feature) {
            print("🔄 [Migration] Routing to LEGACY: \(feature.displayName)")
            return legacyRouter.createViewController(for: feature, context: context)
        } else {
            print("✨ [Migration] Routing to MODERN: \(feature.displayName)")
            let swiftUIView = modernRouter.createView(for: feature, context: context)
            return UIHostingController(rootView: swiftUIView)
        }
    }

    // MARK: - Migration Management
    
    func markFeatureAsMigrated(_ feature: FeatureFlag) {
        migratedFeatures.insert(feature)
        updateMigrationProgress()
        print("✅ [Migration] Feature migrated: \(feature.displayName)")
    }

    func rollbackFeature(_ feature: FeatureFlag) {
        migratedFeatures.remove(feature)
        updateMigrationProgress()
        print("⏮️ [Migration] Feature rolled back: \(feature.displayName)")
    }

    private func updateMigrationProgress() {
        let totalFeatures = FeatureFlag.allCases.count
        let migratedCount = migratedFeatures.count
        migrationProgress = Double(migratedCount) / Double(totalFeatures)
    }

    // MARK: - Info
    
    func getMigrationInfo() -> MigrationInfo {
        MigrationInfo(
            totalFeatures: FeatureFlag.allCases.count,
            migratedCount: migratedFeatures.count,
            remainingCount: FeatureFlag.allCases.count - migratedFeatures.count,
            progress: migrationProgress,
            migratedFeatures: Array(migratedFeatures)
        )
    }
}

// MARK: - Migration Info

struct MigrationInfo {
    let totalFeatures: Int
    let migratedCount: Int
    let remainingCount: Int
    let progress: Double
    let migratedFeatures: [FeatureFlag]
}
