# CombineExtensions

Small, composable extensions for Apple's Combine framework.

## Requirements

- Swift 6.0 or later (Xcode 16+)
- iOS 15+, macOS 12+, tvOS 15+, or watchOS 8+

## Repository structure

```text
Sources/CombineExtensions/          Library implementation
Examples/CombineExtensionsSample/   iOS SwiftUI sample app
Tests/CombineExtensionsTests/       Library tests
```

The sample is an iOS SwiftUI app project. It links the local library package
and shows a simple Combine publisher/subscriber flow, giving new extensions a
place to be exercised interactively.

## Continue development in Xcode

Open `Examples/CombineExtensionsSample/CombineExtensionsSample.xcodeproj` in
Xcode:

1. Choose **File → Open…**.
2. Select the sample `.xcodeproj` file.
3. Select an iPhone Simulator or connected iPhone as the run destination.
4. Run with **Product → Run** or `⌘R`.

The sample project uses a local Swift package dependency pointing to the
repository root, so changes to `Sources/CombineExtensions/` are available
immediately in the app.

Add library code under `Sources/CombineExtensions/`. Add tests under
`Tests/CombineExtensionsTests/`. SwiftPM automatically includes files placed
in those target directories.

The repository uses two spaces for indentation. `.editorconfig` is included so
supported editors and generators use spaces instead of tab characters.

The sample app lives at
`Examples/CombineExtensionsSample/SampleApp.swift`. Use it as
an interactive playground while developing operators and other extensions.

## Build and test from Terminal

```sh
swift build
swift test
```

`swift build` builds the library package. `swift test` runs the library test
target. Build the iOS sample with Xcode or from Terminal:

```sh
xcodebuild \
  -project Examples/CombineExtensionsSample/CombineExtensionsSample.xcodeproj \
  -scheme CombineExtensionsSample \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Add this package to another project

In Xcode, choose **File → Add Package Dependencies… → Add Local…**, then select
the repository folder and add the `CombineExtensions` product to your app
target.

For another Swift package, add the dependency in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-account/CombineExtensions.git", from: "1.0.0")
]
```

Then add `"CombineExtensions"` to the target's dependencies.
