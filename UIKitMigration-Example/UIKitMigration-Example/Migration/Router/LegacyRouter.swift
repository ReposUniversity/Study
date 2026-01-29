//
//  LegacyRouter.swift
//  UIKitMigration-Example
//
//  Migration Layer - Legacy UIKit Router
//

import UIKit

// MARK: - Legacy Router Protocol

protocol LegacyRouter {
    func createViewController(for feature: FeatureFlag, context: NavigationContext) -> UIViewController
}

// MARK: - Legacy Router Implementation

final class LegacyRouterImpl: LegacyRouter {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func createViewController(for feature: FeatureFlag, context: NavigationContext) -> UIViewController {
        switch feature {
        case .userProfile:
            return UserProfileViewController(userRepository: userRepository)
        case .settingsScreen:
            return createPlaceholderViewController(title: "Settings (Legacy)")
        case .productList:
            return createPlaceholderViewController(title: "Product List (Legacy)")
        case .productDetail:
            return createPlaceholderViewController(title: "Product Detail (Legacy)")
        case .shoppingCart:
            return createPlaceholderViewController(title: "Shopping Cart (Legacy)")
        case .paymentFlow:
            return createPlaceholderViewController(title: "Payment (Legacy)")
        case .orderHistory:
            return createPlaceholderViewController(title: "Orders (Legacy)")
        case .searchScreen:
            return createPlaceholderViewController(title: "Search (Legacy)")
        case .notificationsCenter:
            return createPlaceholderViewController(title: "Notifications (Legacy)")
        case .helpSupport:
            return createPlaceholderViewController(title: "Help (Legacy)")
        }
    }

    private func createPlaceholderViewController(title: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = title

        let label = UILabel()
        label.text = "🏛️ \(title)"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])

        return vc
    }
}
