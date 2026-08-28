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
    }
    .padding(24)
  }
}
