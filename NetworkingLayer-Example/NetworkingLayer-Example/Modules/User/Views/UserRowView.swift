//
//  UserRowView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct UserRowView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let username = user.username {
                Text("@\(username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let website = user.website {
                Text(website)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 2)
    }
}