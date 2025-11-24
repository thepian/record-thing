# FlowsLib

A cross-platform Swift package for embedding web content in SwiftUI with JavaScript ↔ Swift communication.

## Platform Support
- **iOS/tvOS**: Uses Capacitor's `CAPBridgeViewController` (full Capacitor plugin support)
- **macOS**: Uses custom `WKWebView` bridge (basic JavaScript communication only)

## Usage

```swift
import SwiftUI
import FlowsLib

struct ContentView: View {
    var body: some View {
        CapacitorView()
    }
}
```

## JavaScript Communication (macOS)

### JavaScript → Swift
```javascript
window.webkit.messageHandlers.bridge.postMessage({
    action: "doSomething",
    data: { key: "value" }
});
```

### Swift → JavaScript
```swift
webView.evaluateJavaScript("yourFunction('hello')") { result, error in
    // Handle result
}
```

## Limitations on macOS
- No Capacitor plugin support (Capacitor doesn't support macOS)
- Basic `WKWebView` functionality only
