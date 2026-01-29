//
//  CrashReportingService.swift
//  UIKitMigration-Example
//
//  Infrastructure Layer - Crash Reporting Service
//

import Foundation

// MARK: - Crash Info

struct CrashInfo {
    let description: String
    let stackTrace: String
    let timestamp: Date
    let featureContext: FeatureFlag?
}

// MARK: - Crash Reporting Service Protocol

protocol CrashReportingService {
    var onCrashDetected: ((CrashInfo) -> Void)? { get set }
    func reportCrash(_ crashInfo: CrashInfo)
    func reportError(_ error: Error, context: [String: Any])
}

// MARK: - Crash Reporting Service Implementation

final class CrashReportingServiceImpl: CrashReportingService {
    var onCrashDetected: ((CrashInfo) -> Void)?
    private var crashes: [CrashInfo] = []

    func reportCrash(_ crashInfo: CrashInfo) {
        crashes.append(crashInfo)
        print("💥 [Crash] \(crashInfo.description)")
        onCrashDetected?(crashInfo)
    }

    func reportError(_ error: Error, context: [String: Any]) {
        print("⚠️ [Error] \(error.localizedDescription) - Context: \(context)")
    }

    func getCrashes() -> [CrashInfo] {
        return crashes
    }
}
