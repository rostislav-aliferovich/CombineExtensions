import Combine
import CombineExtensions
import Testing

@Suite("Publisher.unwrap")
struct PublisherUnwrapTests {
  @Test("removes nil values and preserves order")
  func removesNilValuesAndPreservesOrder() throws {
    let values: [Int?] = [nil, 1, nil, 2, nil, nil, 3, nil]
    var result: [Int]?

    _ = values.publisher
      .unwrap()
      .collect()
      .sink { result = $0 }

    let unwrappedResult = try #require(result)
    #expect(unwrappedResult == [1, 2, 3])
  }

  @Test("publishes no values when every input is nil")
  func publishesNoValuesWhenEveryInputIsNil() throws {
    let values: [Int?] = [nil, nil, nil]
    var result: [Int]?

    _ = values.publisher
      .unwrap()
      .collect()
      .sink { result = $0 }

    let unwrappedResult = try #require(result)
    #expect(unwrappedResult.isEmpty)
  }

  @Test("publishes no values for an empty upstream")
  func publishesNoValuesForEmptyUpstream() throws {
    let values: [Int?] = []
    var result: [Int]?

    _ = values.publisher
      .unwrap()
      .collect()
      .sink { result = $0 }

    let unwrappedResult = try #require(result)
    #expect(unwrappedResult.isEmpty)
  }

  @Test("unwraps one level of nested optionals")
  func unwrapsOneLevelOfNestedOptionals() throws {
    let values: [Int??] = [.some(.some(1)), .some(.none), .none, .some(.some(2))]
    var result: [Int?]?

    _ = values.publisher
      .unwrap()
      .collect()
      .sink { result = $0 }

    let unwrappedResult = try #require(result)
    #expect(unwrappedResult == [1, nil, 2])
  }

  @Test("forwards upstream failures unchanged")
  func forwardsUpstreamFailuresUnchanged() throws {
    enum TestError: Error, Equatable {
      case expected
    }

    let subject = PassthroughSubject<Int?, TestError>()
    var values: [Int]?
    var completion: Subscribers.Completion<TestError>?

    let cancellable = subject
      .unwrap()
      .sink(
        receiveCompletion: { completion = $0 },
        receiveValue: { values = (values ?? []) + [$0] }
      )

    withExtendedLifetime(cancellable) {
      subject.send(1)
      subject.send(nil)
      subject.send(2)
      subject.send(completion: .failure(.expected))
    }

    let receivedValues = try #require(values)
    #expect(receivedValues == [1, 2])

    switch completion {
    case .failure(let error):
      #expect(error == .expected)
    case .finished:
      Issue.record("Expected a failure completion")
    case nil:
      Issue.record("Expected the publisher to complete")
    }
  }
}
