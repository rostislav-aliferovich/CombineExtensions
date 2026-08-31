import Combine
import CombineExtensions
import Testing

@Suite("Publisher.shareReplay")
struct PublisherShareReplayTests {
  @Test("shares one upstream subscription")
  func sharesOneUpstreamSubscription() throws {
    let subject = PassthroughSubject<Int, Never>()
    var subscriptionCount = 0
    let shared = subject
      .handleEvents(receiveSubscription: { _ in subscriptionCount += 1 })
      .shareReplay(2)
    var firstValues: [Int] = []
    var secondValues: [Int] = []

    let first = shared.sink { firstValues.append($0) }
    let second = shared.sink { secondValues.append($0) }

    subject.send(1)
    subject.send(2)

    withExtendedLifetime((first, second)) {
      #expect(subscriptionCount == 1)
      #expect(firstValues == [1, 2])
      #expect(secondValues == [1, 2])
    }
  }

  @Test("replays only the requested number of latest values")
  func replaysOnlyTheRequestedNumberOfLatestValues() throws {
    let subject = PassthroughSubject<Int, Never>()
    let shared = subject.shareReplay(2)
    var firstValues: [Int] = []
    var replayedValues: [Int] = []

    let first = shared.sink { firstValues.append($0) }
    subject.send(1)
    subject.send(2)
    subject.send(3)
    let lateSubscriber = shared.sink { replayedValues.append($0) }

    withExtendedLifetime((first, lateSubscriber)) {
      #expect(firstValues == [1, 2, 3])
      #expect(replayedValues == [2, 3])
    }
  }

  @Test("does not replay values when the buffer size is zero")
  func doesNotReplayValuesWhenBufferSizeIsZero() throws {
    let subject = PassthroughSubject<Int, Never>()
    let shared = subject.shareReplay(0)
    var replayedValues: [Int] = []

    let first = shared.sink { _ in }
    subject.send(1)
    let lateSubscriber = shared.sink { replayedValues.append($0) }
    subject.send(2)

    withExtendedLifetime((first, lateSubscriber)) {
      #expect(replayedValues == [2])
    }
  }

  @Test("replays buffered values before forwarding a terminal failure")
  func replaysBufferedValuesBeforeForwardingTerminalFailure() throws {
    enum TestError: Error, Equatable {
      case expected
    }

    let subject = PassthroughSubject<Int, TestError>()
    let shared = subject.shareReplay(2)
    let first = shared.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(completion: .failure(.expected))

    var replayedValues: [Int] = []
    var replayedCompletion: Subscribers.Completion<TestError>?
    let lateSubscriber = shared.sink(
      receiveCompletion: { replayedCompletion = $0 },
      receiveValue: { replayedValues.append($0) }
    )

    withExtendedLifetime((first, lateSubscriber)) {
      #expect(replayedValues == [2, 3])
      switch replayedCompletion {
      case .failure(let error):
        #expect(error == .expected)
      case .finished:
        Issue.record("Expected the upstream failure to be replayed")
      case nil:
        Issue.record("Expected the late subscriber to complete")
      }
    }
  }

  @Test("replays buffered values before forwarding normal completion")
  func replaysBufferedValuesBeforeForwardingNormalCompletion() {
    let subject = PassthroughSubject<Int, Never>()
    let shared = subject.shareReplay(2)
    let first = shared.sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    subject.send(1)
    subject.send(completion: .finished)

    var replayedValues: [Int] = []
    var didFinish = false
    let lateSubscriber = shared.sink(
      receiveCompletion: { completion in
        if case .finished = completion {
          didFinish = true
        }
      },
      receiveValue: { replayedValues.append($0) }
    )

    withExtendedLifetime((first, lateSubscriber)) {
      #expect(replayedValues == [1])
      #expect(didFinish)
    }
  }
}
