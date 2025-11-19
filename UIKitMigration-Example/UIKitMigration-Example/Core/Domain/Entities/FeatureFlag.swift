//
//  FeatureFlag.swift
//  UIKitMigration-Example
//
//  Core Domain Entity representing feature flags for migration
//

import Foundation

// MARK: - Feature Flag Enum

enum FeatureFlag: String, CaseIterable {
    case userProfile = "user_profile"
    case settingsScreen = "settings_screen"
    case productList = "product_list"
    case productDetail = "product_detail"
    case shoppingCart = "shopping_cart"
    case paymentFlow = "payment_flow"
    case orderHistory = "order_history"
    case searchScreen = "search_screen"
    case notificationsCenter = "notifications_center"
    case helpSupport = "help_support"

    var displayName: String {
        switch self {
        case .userProfile: return "User Profile"
        case .settingsScreen: return "Settings"
        case .productList: return "Product List"
        case .productDetail: return "Product Detail"
        case .shoppingCart: return "Shopping Cart"
        case .paymentFlow: return "Payment Flow"
        case .orderHistory: return "Order History"
        case .searchScreen: return "Search"
        case .notificationsCenter: return "Notifications"
        case .helpSupport: return "Help & Support"
        }
    }

    var migrationComplexity: MigrationComplexity {
        switch self {
        case .userProfile, .settingsScreen: return .low
        case .productList, .searchScreen, .notificationsCenter: return .medium
        case .productDetail, .orderHistory, .helpSupport: return .medium
        case .shoppingCart, .paymentFlow: return .high
        }
    }
}

// MARK: - Migration Complexity
enum MigrationComplexity {
    case low
    case medium
    case high

    var estimatedDays: Int {
        switch self {
        case .low: return 3
        case .medium: return 7
        case .high: return 14
        }
    }
}

// MARK: - Navigation Context
struct NavigationContext {
    let parameters: [String: Any]
    let sourceFeature: FeatureFlag?
    let userContext: UserContext?

    init(
        parameters: [String: Any] = [:],
        sourceFeature: FeatureFlag? = nil,
        userContext: UserContext? = nil
    ) {
        self.parameters = parameters
        self.sourceFeature = sourceFeature
        self.userContext = userContext
    }
}

// MARK: - User Context
struct UserContext {
    let userId: String
    let preferences: UserPreferences
    let permissions: Set<Permission>
}

struct UserPreferences {
    let theme: String
    let language: String
    let accessibility: AccessibilitySettings
}

struct AccessibilitySettings {
    let fontSize: FontSize
    let highContrast: Bool
    let voiceOverEnabled: Bool
}

enum Permission: String {
    case viewProfile
    case editProfile
    case makePayments
    case viewOrders
    case accessSupport
}

enum FontSize: String {
    case small
    case medium
    case large
}
