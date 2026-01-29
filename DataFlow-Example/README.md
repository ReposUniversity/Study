# SwiftUI Data Flow Example

A comprehensive implementation of production-ready data flow patterns in SwiftUI, demonstrating unidirectional architecture, async/await patterns, multi-source synchronization, and robust error handling.

## 📖 Overview

This project showcases how to build predictable, testable, and resilient SwiftUI applications by implementing proper data flow patterns. It addresses common challenges like race conditions, state synchronization, error recovery, and navigation consistency.

## 🎯 Key Concepts

### 1. Unidirectional Data Flow
**File:** `DataFlow/UnidirectionalFlow.swift`

Actions flow in one direction: View → Action → Store → State → View

```swift
enum UserAction {
    case loadUsers
    case searchUsers(String)
    case selectUser(UUID)
    case refreshUsers
    case deleteUser(UUID)
}
```

**Benefits:**
- Predictable state transitions
- Easy debugging and logging
- Simple to test
- Clear data flow path

### 2. Async Flow with Structured Concurrency
**File:** `DataFlow/AsyncFlow.swift`

Leverages Swift's async/await with proper task management and cancellation.

```swift
@MainActor
class AsyncUserViewModel: ObservableObject {
    func loadUsers() {
        loadUsersTask?.cancel() // Cancel previous task
        loadUsersTask = Task {
            // Async work with cancellation checks
        }
    }
}
```

**Benefits:**
- Automatic cancellation on view dismissal
- Concurrent operations with TaskGroup
- Debounced search
- Race condition prevention

### 3. Multi-Source State Synchronization
**File:** `DataFlow/StateSync.swift`

Synchronizes data from network, cache, and local database into a single source of truth.

```swift
Publishers.CombineLatest3(
    networkService.userUpdates,
    localDatabase.userUpdates,
    cacheService.userUpdates
)
.debounce(for: .milliseconds(100), scheduler: syncQueue)
.sink { networkUsers, localUsers, cachedUsers in
    self.reconcileUserStates(...)
}
```

**Benefits:**
- Single source of truth
- Automatic conflict resolution
- Timestamp-based merging
- Offline support

### 4. Resilient Error Handling
**File:** `DataFlow/ErrorHandling.swift`

Wraps data in result types with retry logic, fallbacks, and stale data awareness.

```swift
struct DataFlowResult<T> {
    let data: T?
    let error: DataFlowError?
    let isLoading: Bool
    let lastSuccessfulUpdate: Date?

    var hasStaleData: Bool { ... }
}
```

**Benefits:**
- Graceful degradation
- Automatic retry with exponential backoff
- Fallback data sources
- User-friendly error messages

## 📱 App Structure

### Tab 1: Unidirectional Flow
Demonstrates action-based state management where all state changes flow through explicit actions.

**Features:**
- Action dispatch system
- Centralized state management
- Reactive search with debouncing
- Delete operations

### Tab 2: Async Flow
Shows structured concurrency with async/await, Task cancellation, and concurrent operations.

**Features:**
- Task cancellation
- Concurrent refresh operations
- Debounced search
- Loading states

### Tab 3: Multi-Source Sync
Synchronizes data from multiple sources (network, cache, database) into a single consistent state.

**Features:**
- Real-time sync status
- Conflict resolution
- Last sync timestamp
- Network connectivity handling

### Tab 4: Resilient Flow
Implements robust error handling with retry logic, fallbacks, and stale data awareness.

**Features:**
- Automatic retry
- Stale data detection
- Fallback data sources
- User-friendly error states

### Tab 5: Info
Documentation about each pattern with detailed explanations.

## 🏗️ Architecture

```
DataFlow-Example/
├── DataFlow/
│   ├── UnidirectionalFlow.swift    # Action/State/Store pattern
│   ├── AsyncFlow.swift             # Async/await patterns
│   ├── StateSync.swift             # Multi-source synchronization
│   └── ErrorHandling.swift         # Error handling utilities
├── Models/
│   └── User.swift                  # Domain models
├── Protocols/
│   └── ServiceProtocols.swift      # Service interfaces
├── Services/
│   └── MockUserService.swift       # Mock implementations
├── Views/
│   ├── UserListView.swift          # Unidirectional example
│   ├── AsyncUserListView.swift     # Async example
│   ├── UserDetailView.swift        # Detail screen
│   ├── ResilientDataView.swift     # Generic resilient view
│   └── Components/
│       ├── ErrorViews.swift        # Error UI components
│       ├── SearchBar.swift         # Search component
│       └── UserRowView.swift       # List row component
├── ContentView.swift               # Tab navigation
└── DataFlow_ExampleApp.swift       # App entry point
```

## 🔧 Key Components

### UserStore (Unidirectional Flow)
```swift
class UserStore: ObservableObject {
    @Published private(set) var state = UserState()

    func dispatch(_ action: UserAction) {
        // Handle actions and update state
    }
}
```

### AsyncUserViewModel (Async Flow)
```swift
@MainActor
class AsyncUserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var error: UserError?

    private var loadUsersTask: Task<Void, Never>?
}
```

### StateSynchronizer (Multi-Source Sync)
```swift
@MainActor
class StateSynchronizer: ObservableObject {
    @Published var combinedState = CombinedAppState()

    private func reconcileUserStates(
        network: [User],
        local: [User],
        cached: [User]
    )
}
```

### ResilientDataFlowManager (Error Handling)
```swift
@MainActor
class ResilientDataFlowManager<T>: ObservableObject {
    @Published private(set) var result: DataFlowResult<T>

    func refresh(force: Bool = false)
    func retryIfPossible()
}
```

## 🚀 Getting Started

### Requirements
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Building the Project

```bash
# Clone the repository
cd DataFlow-Example

# Build with Xcode
xcodebuild -project DataFlow-Example.xcodeproj \
           -scheme DataFlow-Example \
           -sdk iphonesimulator \
           build

# Or open in Xcode
open DataFlow-Example.xcodeproj
```

### Running the App

1. Open `DataFlow-Example.xcodeproj` in Xcode
2. Select a simulator or device
3. Press `Cmd + R` to run
4. Explore the different tabs to see each pattern in action

## 🧪 Testing

### Unit Testing Pattern

```swift
func testUserStoreLoadUsers() {
    let mockService = MockUserService()
    let store = UserStore(userService: mockService)

    store.dispatch(.loadUsers)

    // Wait for async operation
    let expectation = XCTestExpectation()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        XCTAssertEqual(store.state.users.count, 5)
        XCTAssertFalse(store.state.isLoading)
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2)
}
```

## 📚 Patterns Explained

### Action-Based State Management

**Problem:** Views mutating state directly leads to unpredictable behavior.

**Solution:** All state changes go through explicit actions.

```swift
// ❌ Bad: Direct mutation
state.users.append(newUser)

// ✅ Good: Action dispatch
store.dispatch(.addUser(newUser))
```

### Task Cancellation

**Problem:** Multiple network requests race, causing UI flicker.

**Solution:** Cancel previous tasks before starting new ones.

```swift
searchTask?.cancel()
searchTask = Task {
    try Task.checkCancellation()
    // Perform work
}
```

### State Reconciliation

**Problem:** Multiple data sources show different versions of data.

**Solution:** Merge based on timestamps and priorities.

```swift
func selectMostRecentUser(
    network: User?,
    local: User?,
    cached: User?
) -> User? {
    return [network, local, cached]
        .compactMap { $0 }
        .max { $0.lastModified < $1.lastModified }
}
```

### Error Recovery

**Problem:** Errors break the app flow and lose data.

**Solution:** Preserve last good data and offer recovery.

```swift
result = DataFlowResult(
    data: result.data, // Keep existing data
    error: dataFlowError,
    isLoading: false,
    lastSuccessfulUpdate: result.lastSuccessfulUpdate
)
```

## 🎨 UI Features

- **Pull to Refresh** - All list views support pull-to-refresh
- **Search** - Debounced search with real-time filtering
- **Error States** - User-friendly error messages with retry
- **Loading States** - Clear loading indicators
- **Empty States** - Helpful empty state messages
- **Navigation** - Type-safe navigation with state-driven routing
- **Stale Data Warnings** - Visual indicators for outdated data

## 🔍 Deep Dive Topics

### Why @MainActor?

SwiftUI requires all view updates on the main thread. Using `@MainActor` ensures all published properties are updated safely.

```swift
@MainActor
class AsyncUserViewModel: ObservableObject {
    @Published var users: [User] = [] // Always updated on main thread
}
```

### Why Combine for Synchronization?

Combine's publishers make it easy to merge multiple reactive streams and apply transformations like debouncing.

```swift
Publishers.CombineLatest3(source1, source2, source3)
    .debounce(for: .milliseconds(100), scheduler: queue)
    .sink { ... }
```

### Navigation as Function of State

Navigation decisions derive from state, not from callbacks.

```swift
// State-driven navigation
.navigationDestination(item: $selectedUserId) { userId in
    UserDetailView(user: store.state.users.first { $0.id == userId })
}
```

## 📖 Related Articles

This implementation is based on the article:
**"Data Flow in SwiftUI: Unidirectional, Async, and Resilient"**

Key takeaways:
- Model features with explicit actions and state
- Use async/await with proper cancellation
- Synchronize multiple sources through a dedicated synchronizer
- Wrap pipelines in error-aware types
- Connect data flow to navigation

## 🤝 Contributing

This is an educational example project. Feel free to:
- Experiment with the patterns
- Add new features
- Try different approaches
- Share improvements

## 📄 License

Copyright © 2025 Matheus Gois. All rights reserved.

This is an educational example project for learning SwiftUI data flow patterns.

## 🙏 Acknowledgments

- SwiftUI team at Apple
- Swift Concurrency design
- Combine framework
- The iOS development community

---

**Built with ❤️ to demonstrate production-ready SwiftUI patterns**
