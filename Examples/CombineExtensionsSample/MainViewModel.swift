//
//  MainViewModel.swift
//  CombineExtensionsSample
//
//  Created by Rostislav Aliferovich on 28.08.2026.
//

import Combine
import CombineExtensions
import Foundation

final class MainViewModel: ObservableObject {
  @Published private(set) var message = "Waiting for a Combine event..."
  @Published private(set) var replayedEvents: [String] = []

  private let events = PassthroughSubject<String, Never>()
  private let sharedEvents: AnyPublisher<String, Never>
  private var cancellables = Set<AnyCancellable>()
  private var replayCancellable: AnyCancellable?

  init() {
    sharedEvents = events
      .shareReplay(2)
      .eraseToAnyPublisher()

    sharedEvents
      .receive(on: DispatchQueue.main)
      .sink { [weak self] value in
        self?.message = value
      }
      .store(in: &cancellables)
  }

  func sendEvent() {
    message = "Sending event..."
    events.send("Received an event at \(Date().formatted(date: .omitted, time: .standard))")
  }

  func subscribeToReplay() {
    replayedEvents = []
    replayCancellable?.cancel()
    replayCancellable = sharedEvents
      .receive(on: DispatchQueue.main)
      .sink { [weak self] value in
        self?.replayedEvents.append(value)
      }
  }
}
