//
//  UserProfileViewController.swift
//  UIKitMigration-Example
//
//  Presentation Layer - Legacy UIKit View Controller
//

import UIKit

// MARK: - User Profile View Controller (Legacy UIKit)

final class UserProfileViewController: UIViewController {
    private let userRepository: UserRepository
    private var users: [User] = []

    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UserCell.self, forCellReuseIdentifier: UserCell.identifier)
        table.delegate = self
        table.dataSource = self
        return table
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUsers()
    }

    private func setupUI() {
        title = "User Profile (Legacy)"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Add badge to indicate legacy
        let badge = UILabel()
        badge.text = "🏛️ LEGACY"
        badge.font = .systemFont(ofSize: 12, weight: .bold)
        badge.textColor = .systemOrange
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: badge)
    }

    private func loadUsers() {
        activityIndicator.startAnimating()

        Task {
            do {
                users = try await userRepository.fetchUsers()
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    showError(error)
                }
            }
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension UserProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as? UserCell else {
            return UITableViewCell()
        }

        let user = users[indexPath.row]
        cell.configure(with: user)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension UserProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = users[indexPath.row]
        print("Selected user: \(user.name)")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - User Cell
final class UserCell: UITableViewCell {
    static let identifier = "UserCell"

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(statusIndicator)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: statusIndicator.leadingAnchor, constant: -8),

            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: statusIndicator.leadingAnchor, constant: -8),

            statusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    func configure(with user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        statusIndicator.backgroundColor = user.isActive ? .systemGreen : .systemRed
    }
}
