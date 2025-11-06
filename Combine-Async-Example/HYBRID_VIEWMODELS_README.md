# Hybrid ViewModels with Combine and Swift Concurrency

A comprehensive implementation of hybrid ViewModels that bridge Combine with async/await for responsive and testable SwiftUI features.

## Overview

This project demonstrates practical patterns for combining Combine and Swift Concurrency to build robust SwiftUI applications. Each paradigm is used where it excels:

- **Combine**: Continuous UI events (search, debouncing, reactive streams)
- **Async/Await**: Discrete operations (fetch, save, sync, structured concurrency)

## Key Features

### 1. Bridging Combine and Async/Await

**Location**: `Utils/CombineAsyncBridge.swift`

Three core conversion patterns:

```swift
// Publisher to async value (Never failure)
let value = await publisher.asyncValue

// Publisher to async Result
let result = await publisher.asyncResult

// Publisher to async throws
let data = try await publisher.asyncThrows()

// Async function to Publisher
let publisher = asyncToPublisher {
    try await asyncFunction()
}
```

**Key Points**:
- Uses continuations safely (resume exactly once)
- Proper cancellation handling
- AsyncPublisher for bridging AsyncStream to Combine

### 2. Hybrid ViewModel Pattern

**Location**: `Presentation/ViewModels/HybridUserViewModel.swift`

Demonstrates:
- Combine for debounced search input
- Async/await for loading users
- Task cancellation when new search starts
- Structured concurrency for parallel operations

**Example Usage**:

```swift
@StateObject private var viewModel = HybridUserViewModel(
    userService: UserService()
)

// Reactive search with debouncing (Combine)
TextField("Search", text: $viewModel.searchText)

// Load data (async/await)
.task {
    await viewModel.loadUsers()
}

// Refresh multiple sources in parallel
Button("Refresh All") {
    Task {
        await viewModel.refreshAllData()
    }
}
```

### 3. Reactive Stream Coordinator

**Location**: `Presentation/ViewModels/ReactiveStreamCoordinator.swift`

Features:
- Merges WebSocket, API, and cache streams
- Priority-based data merging (Live > API > Cache)
- Auto-reconnection with exponential backoff
- Reconciles missed updates after reconnection

**Stream Flow**:

```
WebSocket ─┐
           ├─→ CombineLatest3 ─→ Debounce ─→ Merge ─→ UI
API ───────┤
           │
Cache ─────┘
```

**Key Implementation**:

```swift
Publishers.CombineLatest3(
    webSocketService.liveUpdates,
    apiService.dataUpdates,
    cacheService.cachedData
)
.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
.sink { [weak self] live, api, cached in
    self?.combineStreams(live: live, api: api, cached: cached)
}
```

### 4. Structured Concurrency Manager

**Location**: `Presentation/ViewModels/StructuredConcurrencyManager.swift`

Demonstrates:
- Task groups for parallel processing
- Real-time progress tracking
- Backpressure control with Combine
- Proper cancellation patterns

**Two Processing Modes**:

1. **Task Groups** (parallel, no limit):
```swift
await withTaskGroup(of: ProcessingResult?.self) { group in
    for item in items {
        group.addTask {
            await self.processItem(item)
        }
    }
    // Track progress as results arrive
}
```

2. **Backpressure** (max concurrent):
```swift
items.publisher
    .flatMap(maxPublishers: .max(3)) { item in
        Future { promise in
            Task {
                let result = await self.processItem(item)
                promise(.success(result))
            }
        }
    }
```

## Project Structure

```
Combine_Async-Example/
├── Utils/
│   └── CombineAsyncBridge.swift          # Publisher ↔ Async conversion
├── Domain/
│   └── Entities/
│       ├── User.swift                     # User models
│       ├── StreamData.swift               # Stream data models
│       └── ProcessingItem.swift           # Processing models
├── Data/
│   └── Services/
│       ├── UserService.swift              # User API service
│       └── StreamServices.swift           # WebSocket, API, Cache services
└── Presentation/
    ├── ViewModels/
    │   ├── HybridUserViewModel.swift     # Hybrid Combine + Async ViewModel
    │   ├── ReactiveStreamCoordinator.swift # Stream merging coordinator
    │   └── StructuredConcurrencyManager.swift # Task group manager
    └── Views/
        ├── HybridExamplesView.swift      # Main navigation hub
        ├── HybridUsersView.swift         # User search example
        ├── ReactiveStreamView.swift      # Stream coordination example
        └── StructuredProcessingView.swift # Batch processing example
```

## Examples

### Example 1: Hybrid Users View

**Features**:
- Debounced search (300ms)
- Async user loading
- Parallel data refresh (profiles + preferences + sync)
- Error handling with banner

**Pattern**:
```
User types → Combine debounces → Task performs search → UI updates
```

### Example 2: Reactive Stream View

**Features**:
- Real-time WebSocket updates every 3s
- Periodic API polling every 5s
- Cache priming on launch
- Connection status indicator
- Auto-reconnect with backoff (1s, 2s, 4s, 8s, ... max 30s)

**Pattern**:
```
Connect → Stream starts → Disconnect → Auto-reconnect → Fetch missed updates
```

### Example 3: Structured Processing View

**Features**:
- Configurable item count (1-50)
- Two modes: Task groups vs Backpressure
- Live progress bar
- Success/failure tracking
- Processing time metrics

**Pattern**:
```
Start → Process items in parallel → Track progress → Display results
```

## Implementation Checklist

- [x] Drop in the bridge file (`CombineAsyncBridge.swift`)
- [x] Define service protocols with Publisher outputs
- [x] Implement async internals, wrap with `asyncToPublisher`
- [x] Build hybrid ViewModels with debouncing and cancellation
- [x] Add stream coordinator for live features and reconnection
- [x] Use task groups for batch jobs or Combine for backpressure
- [x] Add SwiftUI views with proper state management

## Key Patterns

### Pattern 1: Reactive Input + Async Work

```swift
// Combine observes input
$searchText
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { query in
        self.performSearch(query)  // Triggers async work
    }

// Async performs the work
private func performSearch(_ query: String) {
    searchTask?.cancel()  // Cancel previous
    searchTask = Task {
        let results = try await service.search(query).asyncThrows()
        await MainActor.run {
            self.searchResults = results
        }
    }
}
```

### Pattern 2: Stream Merging

```swift
Publishers.CombineLatest3(stream1, stream2, stream3)
    .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
    .sink { data1, data2, data3 in
        let merged = self.merge(data1, data2, data3)
        self.publish(merged)
    }
```

### Pattern 3: Structured Concurrency

```swift
await withTaskGroup(of: Result.self) { group in
    for item in items {
        group.addTask {
            await self.process(item)
        }
    }

    for await result in group {
        guard !Task.isCancelled else { break }
        self.results.append(result)
        self.progress += 1.0 / Double(items.count)
    }
}
```

## Best Practices

### Cancellation

Always cancel previous work before starting new:

```swift
private var searchTask: Task<Void, Never>?

func performSearch(_ query: String) {
    searchTask?.cancel()  // Critical!
    searchTask = Task {
        // Check cancellation before UI updates
        guard !Task.isCancelled else { return }
        // ... update UI
    }
}
```

### Main Actor

Use `@MainActor` on ViewModels to ensure thread safety:

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
    // All property accesses are on MainActor
}
```

### Protocol Boundaries

Keep services protocol-based for testability:

```swift
protocol UserServiceProtocol {
    func fetchUsers() -> AnyPublisher<[User], Error>
}

class MockUserService: UserServiceProtocol {
    var mockUsers: [User] = []

    func fetchUsers() -> AnyPublisher<[User], Error> {
        Just(mockUsers)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
```

## Testing Patterns

### Mock Services

```swift
class MockUserService: UserServiceProtocol {
    var mockUsers: [User] = User.mockUsers
    var shouldFail = false

    func fetchUsers() -> AnyPublisher<[User], Error> {
        if shouldFail {
            return Fail(error: TestError.mock)
                .eraseToAnyPublisher()
        }
        return Just(mockUsers)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
```

### Test ViewModel

```swift
@MainActor
func testSearch() async {
    let service = MockUserService()
    let viewModel = HybridUserViewModel(userService: service)

    await viewModel.loadUsers()
    XCTAssertEqual(viewModel.users.count, 8)

    viewModel.searchText = "Alice"
    try? await Task.sleep(nanoseconds: 400_000_000) // Wait for debounce
    XCTAssertEqual(viewModel.searchResults.count, 1)
}
```

## Gotchas

1. **Double Resume**: Continuations must resume exactly once
   - Solution: Use proper switch statements and guard clauses

2. **Main Thread Updates**: UI updates from background threads
   - Solution: Use `@MainActor` or `MainActor.run { }`

3. **Task Cancellation**: Forgetting to check `Task.isCancelled`
   - Solution: Guard before expensive work and UI updates

4. **Memory Leaks**: Strong references in closures
   - Solution: Always use `[weak self]` in sink handlers

5. **Continuation Leaks**: Not cancelling AnyCancellable after resume
   - Solution: Store and cancel after continuation resumes

## Performance Tips

- Use `debounce` to reduce excessive searches (300ms is a good default)
- Implement backpressure with `flatMap(maxPublishers:)` for controlled concurrency
- Use `first()` when you only need one value from a stream
- Cancel obsolete tasks immediately to free resources
- Cap reconnection delays to protect battery and quota (30s max)

## Benefits

- **Responsive UI**: Combine keeps UI reactive without lag
- **Clean Code**: Each paradigm does what it does best
- **Testable**: Protocol boundaries enable mocking
- **Cancellation**: Proper cleanup prevents wasted work
- **Maintainable**: Convert at edges, keep internals simple

## Summary

**Convert at the edges, keep each layer single-paradigm inside.**

Use Combine for streams, async/await for discrete work, and bridge safely at boundaries. This approach gives you:

- ✅ Reactive UI updates
- ✅ Simple async operations
- ✅ Proper cancellation
- ✅ Easy testing
- ✅ Clear architecture

## References

Based on the Medium article: "Hybrid ViewModels with Combine and Swift Concurrency - A practical playbook for bridging Combine with async/await to ship responsive and testable SwiftUI features."

## License

Copyright © 2025 Matheus Gois. All rights reserved.
