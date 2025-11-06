//
//  ContentView.swift
//  Copyright © 2025 Matheus Gois. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TasksView(viewModel: DIContainer.shared.makeTasksViewModel())
    }
}

#Preview {
    ContentView()
}
