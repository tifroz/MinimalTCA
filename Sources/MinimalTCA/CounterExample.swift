// 82 Lines by Claude Sonnet
// Minimal TCA: Complete counter example demonstrating the architecture

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

// MARK: - Usage Example

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
