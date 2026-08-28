//
//  MainViewModel.swift
//  CombineExtensionsSample
//
//  Created by Rostislav Aliferovich on 28.08.2026.
//

import Combine
import Foundation

final class MainViewModel: ObservableObject {
  @Published private(set) var message = "Waiting for a Combine event..."

  private let events = PassthroughSubject<String, Never>()
  private var cancellables = Set<AnyCancellable>()

  init() {
    events
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
}
