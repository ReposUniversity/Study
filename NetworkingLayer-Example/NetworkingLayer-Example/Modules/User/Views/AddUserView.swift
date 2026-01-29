//
//  AddUserView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct AddUserView: View {
    @Binding var isPresented: Bool
    let onAddUser: (String, String) -> Void
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAddUser(name, email)
                        isPresented = false
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}