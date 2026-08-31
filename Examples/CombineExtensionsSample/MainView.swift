//
//  MainView.swift
//  CombineExtensionsSample
//
//  Created by Rostislav Aliferovich on 28.08.2026.
//

import SwiftUI

struct MainView: View {
  @StateObject private var viewModel = MainViewModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("CombineExtensions")
        .font(.largeTitle)
        .bold()

      Text("iOS sample app")
        .foregroundStyle(.secondary)

      Divider()

      Text(viewModel.message)
        .frame(maxWidth: .infinity, alignment: .leading)

      Button("Send event") {
        viewModel.sendEvent()
      }
      .buttonStyle(.borderedProminent)

      Button("Subscribe and replay last 2 events") {
        viewModel.subscribeToReplay()
      }

      Text("Replay subscriber")
        .font(.headline)
      Text(viewModel.replayedEvents.joined(separator: "\n"))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
    }
    .padding(24)
  }
}
