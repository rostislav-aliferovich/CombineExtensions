# CombineExtensions

Small, composable extensions for Apple's Combine framework.

## Requirements

- Swift 5.9 or later
- iOS 15+, macOS 12+, tvOS 15+, or watchOS 8+

## Installation

Add the package URL in Xcode through **File → Add Package Dependencies**, or add
the dependency to another package:

```swift
dependencies: [
    .package(url: "https://github.com/your-account/CombineExtensions.git", from: "1.0.0")
]
```

Then add `CombineExtensions` to the target's dependencies.

## Included extensions

```swift
import Combine
import CombineExtensions

let cancellable = URLSession.shared
    .dataTaskPublisher(for: url)
    .mapToVoid()
    .sink {
        print("Request completed successfully")
    }
```

The value-only `sink(receiveValue:)` convenience ignores completion events. As
with every Combine subscription, retain the returned `AnyCancellable` for as
long as the subscription should remain active.
