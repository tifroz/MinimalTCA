// 59 Lines by Claude Sonnet
// Minimal TCA: Core Reducer protocol with composition support (Android-compatible, no Combine)

import Foundation

/// A protocol that defines the core logic of a feature.
///
/// Reducers are pure functions that take the current state and an action,
/// and return a new state along with any effects to run.
public protocol Reducer<State, Action> {
  /// The state type managed by this reducer
  associatedtype State

  /// The action type handled by this reducer
  associatedtype Action

  /// Reduces the current state with an action to produce a new state and effects
  ///
  /// - Parameters:
  ///   - state: A mutable reference to the current state
  ///   - action: The action to process
  /// - Returns: An effect representing asynchronous work
  func reduce(into state: inout State, action: Action) -> Effect<Action>
}

// MARK: - Reducer Composition

extension Reducer {
  /// Combines this reducer with another reducer
  ///
  /// Both reducers run sequentially, allowing you to compose features together
  public func combined<Other: Reducer>(
    with other: Other
  ) -> CombinedReducer<Self, Other> where Other.State == State, Other.Action == Action {
    CombinedReducer(first: self, second: other)
  }

  /// Transforms this reducer to work on optional state
  ///
  /// Useful for parent features that contain optional child features
  public func optional() -> OptionalReducer<Self> {
    OptionalReducer(base: self)
  }
}

// MARK: - Internal Reducer Combinators

public struct CombinedReducer<R1: Reducer, R2: Reducer>: Reducer
where R1.State == R2.State, R1.Action == R2.Action {
  let first: R1
  let second: R2

  public func reduce(into state: inout R1.State, action: R1.Action) -> Effect<R1.Action> {
    let effect1 = first.reduce(into: &state, action: action)
    let effect2 = second.reduce(into: &state, action: action)
    return .merge(effect1, effect2)
  }
}

public struct OptionalReducer<Base: Reducer>: Reducer {
  let base: Base

  public func reduce(into state: inout Base.State?, action: Base.Action) -> Effect<Base.Action> {
    guard state != nil else { return .none }
    return base.reduce(into: &state!, action: action)
  }
}
