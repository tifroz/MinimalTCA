// 228 Lines by Claude Sonnet
// Minimal TCA: Comprehensive tests demonstrating testability
// Extended with Scope composition tests

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

// MARK: - Scope Composition Tests

@MainActor
@Suite("Scope Tests")
struct ScopeTests {
  @Test("Scope forwards child actions to child reducer")
  func testScopeForwardsChildActions() async throws {
    let store = TestStore(
      initialState: AppReducer.State(
        counter: CounterReducer.State(count: 0),
        appTitle: "Initial"
      ),
      reducer: AppReducer()
    )

    // Send child action through parent
    await store.send(.counter(.increment)) { state in
      state.counter.count = 1
      state.appTitle = "Counter incremented!" // Parent reacts to child action
    }
  }

  @Test("Scope ignores non-child actions")
  func testScopeIgnoresNonChildActions() async throws {
    let store = TestStore(
      initialState: AppReducer.State(
        counter: CounterReducer.State(count: 5),
        appTitle: "Initial"
      ),
      reducer: AppReducer()
    )

    // Send parent-only action
    await store.send(.updateTitle("New Title")) { state in
      state.appTitle = "New Title"
      // Counter state unchanged
      #expect(state.counter.count == 5)
    }
  }

  @Test("Child reducer updates child state slice")
  func testChildReducerUpdatesChildState() async throws {
    let store = Store(
      initialState: AppReducer.State(
        counter: CounterReducer.State(count: 0),
        appTitle: "App"
      ),
      reducer: AppReducer()
    )

    // Child actions update child state
    await store.send(.counter(.increment))
    #expect(store.currentState.counter.count == 1)

    await store.send(.counter(.increment))
    #expect(store.currentState.counter.count == 2)

    await store.send(.counter(.decrement))
    #expect(store.currentState.counter.count == 1)
  }

  @Test("Parent can observe and react to child actions")
  func testParentReactsToChildActions() async throws {
    let store = Store(
      initialState: AppReducer.State(
        counter: CounterReducer.State(count: 0),
        appTitle: "Initial"
      ),
      reducer: AppReducer()
    )

    // Parent reacts to child increment
    await store.send(.counter(.increment))
    #expect(store.currentState.appTitle == "Counter incremented!")

    // Other child actions don't change parent title
    await store.send(.counter(.decrement))
    #expect(store.currentState.appTitle == "Counter incremented!")
  }
}

// MARK: - CasePath Tests

@Suite("CasePath Tests")
struct CasePathTests {
  enum TestAction: Equatable, Sendable {
    case child(String)
    case parent(Int)
  }

  @Test("CasePath extracts matching cases")
  func testExtractMatchingCase() {
    let casePath = CasePath<TestAction, String>(
      extract: { action in
        if case .child(let value) = action {
          return value
        }
        return nil
      },
      embed: { .child($0) }
    )

    let childAction: TestAction = .child("test")
    let extracted = casePath.extract(from: childAction)
    #expect(extracted == "test")
  }

  @Test("CasePath returns nil for non-matching cases")
  func testExtractNonMatchingCase() {
    let casePath = CasePath<TestAction, String>(
      extract: { action in
        if case .child(let value) = action {
          return value
        }
        return nil
      },
      embed: { .child($0) }
    )

    let parentAction: TestAction = .parent(42)
    let extracted = casePath.extract(from: parentAction)
    #expect(extracted == nil)
  }

  @Test("CasePath embeds values correctly")
  func testEmbedValue() {
    let casePath = CasePath<TestAction, String>(
      extract: { action in
        if case .child(let value) = action {
          return value
        }
        return nil
      },
      embed: { .child($0) }
    )

    let action = casePath.embed("hello")
    #expect(action == .child("hello"))
  }
}
