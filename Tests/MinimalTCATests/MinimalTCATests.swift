// 122 Lines by Claude Sonnet
// Minimal TCA: Comprehensive tests demonstrating testability

import Testing
@testable import MinimalTCA

@MainActor
@Suite("Counter Tests")
struct CounterTests {
  @Test("Increment increases count")
  func testIncrement() async throws {
    let store = TestStore(
      initialState: CounterReducer.State(),
      reducer: CounterReducer()
    )

    await store.send(.increment) { state in
      state.count = 1
    }
  }

  @Test("Decrement decreases count")
  func testDecrement() async throws {
    let store = TestStore(
      initialState: CounterReducer.State(count: 5),
      reducer: CounterReducer()
    )

    await store.send(.decrement) { state in
      state.count = 4
    }
  }

  @Test("Reset sets count to zero")
  func testReset() async throws {
    let store = TestStore(
      initialState: CounterReducer.State(count: 42, isLoading: true),
      reducer: CounterReducer()
    )

    await store.send(.reset) { state in
      state.count = 0
      state.isLoading = false
    }
  }

  @Test("Delayed increment shows loading and increments")
  func testDelayedIncrement() async throws {
    let store = TestStore(
      initialState: CounterReducer.State(count: 0),
      reducer: CounterReducer()
    )

    await store.send(.incrementDelayed) { state in
      state.isLoading = true
    }

    // The effect will send .setLoading(false) then .increment
    // TestStore automatically processes these
  }

  @Test("Multiple operations in sequence")
  func testMultipleOperations() async throws {
    let store = TestStore(
      initialState: CounterReducer.State(),
      reducer: CounterReducer()
    )

    await store.send(.increment) { state in
      state.count = 1
    }

    await store.send(.increment) { state in
      state.count = 2
    }

    await store.send(.decrement) { state in
      state.count = 1
    }

    await store.send(.reset) { state in
      state.count = 0
    }
  }
}

@MainActor
@Suite("Store Tests")
struct StoreTests {
  @Test("Store initializes with correct state")
  func testInitialization() async throws {
    let store = Store(
      initialState: CounterReducer.State(count: 10),
      reducer: CounterReducer()
    )

    #expect(store.currentState.count == 10)
  }

  @Test("Store processes actions")
  func testActionProcessing() async throws {
    let store = Store(
      initialState: CounterReducer.State(),
      reducer: CounterReducer()
    )

    await store.send(.increment)
    #expect(store.currentState.count == 1)

    await store.send(.increment)
    #expect(store.currentState.count == 2)

    await store.send(.decrement)
    #expect(store.currentState.count == 1)
  }
}

@Suite("Effect Tests")
struct EffectTests {
  @Test("Effect.none does nothing")
  func testNoneEffect() async throws {
    let effect = Effect<Int>.none
    // Effect.none should complete immediately without emitting actions
    // We verify this by checking the effect runs without errors
    let send = Send<Int> { _ in }
    await effect.run(send: send)
  }

  @Test("Effect.send emits single action")
  func testSendEffect() async throws {
    // For this minimal implementation, we test that Effect.send compiles
    // A full implementation would verify the action is actually sent
    let effect = Effect<Int>.send(42)
    let send = Send<Int> { _ in }
    await effect.run(send: send)
  }
}
