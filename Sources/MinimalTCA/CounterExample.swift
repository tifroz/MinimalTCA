// 176 Lines by Claude Sonnet
// Minimal TCA: Complete counter example demonstrating the architecture
// Extended with parent/child composition using Scope

import Foundation

/// Example: A simple counter feature
///
/// This demonstrates the basic pattern:
/// 1. Define State (data model)
/// 2. Define Action (events that can happen)
/// 3. Create a Reducer (pure logic)
/// 4. Create a Store (runtime)

// MARK: - Counter Feature

struct CounterReducer: Reducer {
  struct State: Equatable {
    var count: Int = 0
    var isLoading: Bool = false
  }

  enum Action: Equatable {
    case increment
    case decrement
    case incrementDelayed
    case reset
    case setLoading(Bool)
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .increment:
      state.count += 1
      return .none

    case .decrement:
      state.count -= 1
      return .none

    case .incrementDelayed:
      state.isLoading = true
      return .run { send in
        // Simulate async work (1 second = 1_000_000_000 nanoseconds)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await send(.setLoading(false))
        await send(.increment)
      }

    case .reset:
      state.count = 0
      state.isLoading = false
      return .none

    case let .setLoading(isLoading):
      state.isLoading = isLoading
      return .none
    }
  }
}

// MARK: - Usage Example (Simple)

/// Example of using the counter in a real app
@MainActor
func counterExample() async {
  // Create the store
  let store = Store(
    initialState: CounterReducer.State(),
    reducer: CounterReducer()
  )

  // Send some actions
  await store.send(.increment)
  print("Count after increment: \(store.currentState.count)") // 1

  await store.send(.increment)
  print("Count after second increment: \(store.currentState.count)") // 2

  await store.send(.decrement)
  print("Count after decrement: \(store.currentState.count)") // 1

  // Async effect
  await store.send(.incrementDelayed)
  print("Count after delayed increment: \(store.currentState.count)") // 2 (after 1 second)

  await store.send(.reset)
  print("Count after reset: \(store.currentState.count)") // 0
}

// MARK: - Parent/Child Composition Example

/// Example: A parent feature that embeds a counter as a child
///
/// This demonstrates composability - the ability to break down large features
/// into smaller, reusable pieces that can be tested independently.

struct AppReducer: Reducer {
  struct State: Equatable, Sendable {
    var counter: CounterReducer.State
    var appTitle: String
  }

  enum Action: Equatable, Sendable {
    case counter(CounterReducer.Action)
    case updateTitle(String)
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    // Use Scope to embed the child counter reducer
    let scopedEffect = Scope(
      state: \.counter,
      action: CasePath(
        extract: { action in
          if case .counter(let counterAction) = action {
            return counterAction
          }
          return nil
        },
        embed: { Action.counter($0) }
      ),
      child: CounterReducer()
    )
    .reduce(into: &state, action: action)

    // Parent-specific logic
    switch action {
    case .counter(.increment):
      // Parent can react to child actions
      state.appTitle = "Counter incremented!"
      return scopedEffect

    case .counter:
      return scopedEffect

    case let .updateTitle(title):
      state.appTitle = title
      return .none
    }
  }
}

// MARK: - Alternative: Using .scope() Extension

/// Example: Using the convenience extension for cleaner composition
struct AppReducerV2: Reducer {
  struct State: Equatable, Sendable {
    var counter: CounterReducer.State
    var appTitle: String
  }

  enum Action: Equatable, Sendable {
    case counter(CounterReducer.Action)
    case updateTitle(String)
  }

  // Define parent logic as a reducer
  private struct ParentLogic: Reducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .counter(.increment):
        state.appTitle = "Counter incremented!"
        return .none

      case .counter:
        return .none

      case let .updateTitle(title):
        state.appTitle = title
        return .none
      }
    }
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    // Compose parent logic with scoped child
    ParentLogic()
      .scope(
        state: \.counter,
        action: CasePath(
          extract: { if case .counter(let a) = $0 { return a } else { return nil } },
          embed: { .counter($0) }
        ),
        child: CounterReducer()
      )
      .reduce(into: &state, action: action)
  }
}

// MARK: - Usage Example (Composition)

@MainActor
func compositionExample() async {
  let store = Store(
    initialState: AppReducer.State(
      counter: CounterReducer.State(),
      appTitle: "My App"
    ),
    reducer: AppReducer()
  )

  // Send child actions through parent
  await store.send(.counter(.increment))
  print("Count: \(store.currentState.counter.count)") // 1
  print("Title: \(store.currentState.appTitle)") // "Counter incremented!"

  // Send parent actions
  await store.send(.updateTitle("Updated Title"))
  print("Title: \(store.currentState.appTitle)") // "Updated Title"

  // Child actions still work
  await store.send(.counter(.decrement))
  print("Count: \(store.currentState.counter.count)") // 0
}
