//
//  SearchBar.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let onSubmit: (String) -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search users...", text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    onSubmit(text)
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onSubmit("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.gray))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
