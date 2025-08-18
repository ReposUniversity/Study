//
//  TodoDetailView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct TodoDetailView: View {
    let todo: TodoEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Todo Details")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("ID: \(todo.id)")
                    .font(.headline)
                
                Text("User ID: \(todo.userId)")
                    .font(.headline)
                
                Text("Title:")
                    .font(.headline)
                Text(todo.title)
                    .font(.body)
                    .padding(.leading)
                
                HStack {
                    Text("Status:")
                        .font(.headline)
                    Text(todo.completed ? "✅ Completed" : "❌ Not Completed")
                        .foregroundColor(todo.completed ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Todo \(todo.id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
