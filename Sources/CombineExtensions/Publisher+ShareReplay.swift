import Combine
import Foundation

public extension Publisher {
  /// Shares one upstream subscription and replays the most recent values to new subscribers.
  ///
  /// The replay buffer is shared by all subscribers. A buffer size of zero behaves like
  /// `share()`. Passing a negative buffer size traps with a precondition failure.
  func shareReplay(_ bufferSize: Int) -> Publishers.ShareReplay<Self> {
    Publishers.ShareReplay(upstream: self, bufferSize: bufferSize)
  }
}

public extension Publishers {
  struct ShareReplay<Upstream: Publisher>: Publisher {
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    private let publisher: Publishers.Autoconnect<Publishers.Multicast<Upstream, ReplaySubject<Output, Failure>>>

    fileprivate init(upstream: Upstream, bufferSize: Int) {
      precondition(bufferSize >= 0, "shareReplay buffer size must be non-negative")

      let subject = ReplaySubject<Output, Failure>(bufferSize: bufferSize)
      publisher = upstream
        .multicast(subject: subject)
        .autoconnect()
    }

    public func receive<S>(subscriber: S)
    where S: Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
      publisher.receive(subscriber: subscriber)
    }
  }
}

private final class ReplaySubject<Output, Failure: Error>: Subject {
  private let lock = NSLock()
  private let bufferSize: Int
  private var buffer: [Output] = []
  private var completion: Subscribers.Completion<Failure>?
  private var subscriptions: [ObjectIdentifier: ReplaySubscription<Output, Failure>] = [:]

  init(bufferSize: Int) {
    self.bufferSize = bufferSize
  }

  func send(subscription: any Subscription) {
    subscription.request(.unlimited)
  }

  func send(_ input: Output) {
    let currentSubscriptions: [ReplaySubscription<Output, Failure>]

    lock.lock()
    guard completion == nil else {
      lock.unlock()
      return
    }

    if bufferSize > 0 {
      buffer.append(input)
      if buffer.count > bufferSize {
        buffer.removeFirst(buffer.count - bufferSize)
      }
    }
    currentSubscriptions = Array(subscriptions.values)
    lock.unlock()

    currentSubscriptions.forEach { $0.enqueue(input) }
  }

  func send(completion: Subscribers.Completion<Failure>) {
    let currentSubscriptions: [ReplaySubscription<Output, Failure>]

    lock.lock()
    guard self.completion == nil else {
      lock.unlock()
      return
    }

    self.completion = completion
    currentSubscriptions = Array(subscriptions.values)
    lock.unlock()

    currentSubscriptions.forEach { $0.finish(completion) }
  }

  func receive<S>(subscriber: S)
  where S: Subscriber, S.Input == Output, S.Failure == Failure {
    let subscription = ReplaySubscription(
      subscriber: subscriber,
      subject: self,
      bufferSize: bufferSize
    )

    lock.lock()
    subscription.setInitialState(buffer: buffer, completion: completion)
    subscriptions[subscription.id] = subscription
    lock.unlock()

    subscriber.receive(subscription: subscription)
    subscription.startDraining()
  }

  fileprivate func remove(_ subscription: ReplaySubscription<Output, Failure>) {
    lock.lock()
    subscriptions.removeValue(forKey: subscription.id)
    lock.unlock()
  }
}

private final class ReplaySubscription<Output, Failure: Error>: Subscription {
  private enum DrainAction {
    case value(Output)
    case completion(Subscribers.Completion<Failure>)
    case stop
  }

  private let identity: UUIDBox
  let id: ObjectIdentifier

  private let lock = NSLock()
  private let downstream: AnySubscriber<Output, Failure>
  private let bufferSize: Int
  private weak var subject: ReplaySubject<Output, Failure>?
  private var pending: [Output] = []
  private var demand: Subscribers.Demand = .none
  private var completion: Subscribers.Completion<Failure>?
  private var isDraining = false
  private var isCancelled = false

  init<S: Subscriber>(
    subscriber: S,
    subject: ReplaySubject<Output, Failure>,
    bufferSize: Int
  )
  where S.Input == Output, S.Failure == Failure {
    identity = UUIDBox()
    id = ObjectIdentifier(identity)
    downstream = AnySubscriber(subscriber)
    self.bufferSize = bufferSize
    self.subject = subject
  }

  func setInitialState(buffer: [Output], completion: Subscribers.Completion<Failure>?) {
    lock.lock()
    pending = buffer
    self.completion = completion
    lock.unlock()
  }

  func request(_ newDemand: Subscribers.Demand) {
    guard newDemand != .none else { return }

    lock.lock()
    guard !isCancelled else {
      lock.unlock()
      return
    }

    demand += newDemand
    let shouldDrain = beginDrainingIfNeeded()
    lock.unlock()

    if shouldDrain {
      drain()
    }
  }

  func cancel() {
    lock.lock()
    guard !isCancelled else {
      lock.unlock()
      return
    }

    isCancelled = true
    pending.removeAll()
    lock.unlock()

    subject?.remove(self)
  }

  func enqueue(_ value: Output) {
    lock.lock()
    guard !isCancelled, completion == nil else {
      lock.unlock()
      return
    }

    if bufferSize > 0 {
      pending.append(value)
      if pending.count > bufferSize {
        pending.removeFirst(pending.count - bufferSize)
      }
    } else if demand != .none {
      pending.append(value)
    }
    let shouldDrain = beginDrainingIfNeeded()
    lock.unlock()

    if shouldDrain {
      drain()
    }
  }

  func finish(_ completion: Subscribers.Completion<Failure>) {
    lock.lock()
    guard !isCancelled, self.completion == nil else {
      lock.unlock()
      return
    }

    self.completion = completion
    let shouldDrain = beginDrainingIfNeeded()
    lock.unlock()

    if shouldDrain {
      drain()
    }
  }

  func startDraining() {
    lock.lock()
    let shouldDrain = beginDrainingIfNeeded()
    lock.unlock()

    if shouldDrain {
      drain()
    }
  }

  private func beginDrainingIfNeeded() -> Bool {
    guard !isDraining else { return false }
    isDraining = true
    return true
  }

  private func drain() {
    while true {
      let action: DrainAction

      lock.lock()
      if isCancelled {
        isDraining = false
        action = .stop
      } else if !pending.isEmpty, demand != .none {
        let value = pending.removeFirst()
        if demand != .unlimited {
          demand -= .max(1)
        }
        action = .value(value)
      } else if pending.isEmpty, let completion {
        isCancelled = true
        isDraining = false
        action = .completion(completion)
      } else {
        isDraining = false
        action = .stop
      }
      lock.unlock()

      switch action {
      case .value(let value):
        let additionalDemand = downstream.receive(value)
        lock.lock()
        if !isCancelled {
          demand += additionalDemand
        }
        lock.unlock()
      case .completion(let completion):
        downstream.receive(completion: completion)
        subject?.remove(self)
        return
      case .stop:
        return
      }
    }
  }
}

private final class UUIDBox {}
