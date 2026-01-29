//
//  UserDetailView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct UserDetailView: View {
    let user: User

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text(user.name.prefix(1))
                            .font(.system(size: 50))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .shadow(radius: 10)

                // User Info
                VStack(spacing: 8) {
                    Text(user.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Circle()
                            .fill(user.isActive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(user.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()
                    .padding(.horizontal)

                // Bio Section
                if let bio = user.bio {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)

                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)

                    DetailRow(
                        icon: "clock",
                        title: "Last Modified",
                        value: formatDate(user.lastModified)
                    )

                    DetailRow(
                        icon: "number",
                        title: "User ID",
                        value: user.id.uuidString.prefix(8) + "..."
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical, 24)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}
