import Combine

public extension Publisher {
  /// Publishes each non-`nil` value emitted by this publisher.
  ///
  /// This removes one level of optionality from the output. Values are
  /// published in their original order, and upstream failures are forwarded
  /// unchanged.
  func unwrap<T>() -> Publishers.CompactMap<Self, T> where Self.Output == Optional<T> {
    compactMap { $0 }
  }
}
