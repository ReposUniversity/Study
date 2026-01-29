//
//  ModernRouter.swift
//  UIKitMigration-Example
//
//  Migration Layer - Modern SwiftUI Router
//

import SwiftUI

// MARK: - Modern Router Protocol

protocol ModernRouter {
    func createView(for feature: FeatureFlag, context: NavigationContext) -> AnyView
}

// MARK: - Modern Router Implementation

final class ModernRouterImpl: ModernRouter {
    private let userUseCase: UserUseCase

    init(userUseCase: UserUseCase) {
        self.userUseCase = userUseCase
    }

    func createView(for feature: FeatureFlag, context: NavigationContext) -> AnyView {
        switch feature {
        case .userProfile:
            return AnyView(UserProfileView(userUseCase: userUseCase))
        case .settingsScreen:
            return AnyView(createPlaceholderView(title: "Settings (Modern)"))
        case .productList:
            return AnyView(createPlaceholderView(title: "Product List (Modern)"))
        case .productDetail:
            return AnyView(createPlaceholderView(title: "Product Detail (Modern)"))
        case .shoppingCart:
            return AnyView(createPlaceholderView(title: "Shopping Cart (Modern)"))
        case .paymentFlow:
            return AnyView(createPlaceholderView(title: "Payment (Modern)"))
        case .orderHistory:
            return AnyView(createPlaceholderView(title: "Orders (Modern)"))
        case .searchScreen:
            return AnyView(createPlaceholderView(title: "Search (Modern)"))
        case .notificationsCenter:
            return AnyView(createPlaceholderView(title: "Notifications (Modern)"))
        case .helpSupport:
            return AnyView(createPlaceholderView(title: "Help (Modern)"))
        }
    }

    private func createPlaceholderView(title: String) -> some View {
        VStack {
            Text("✨ \(title)")
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
    }
}
