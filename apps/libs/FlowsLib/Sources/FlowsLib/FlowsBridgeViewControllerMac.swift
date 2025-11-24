//
//  FlowsBridgeViewControllerMac.swift
//  FlowsLib
//
//  Created for macOS AppKit support
//

#if canImport(AppKit)
import AppKit
import WebKit

/// Custom bridge view controller for macOS
/// Note: Capacitor doesn't support macOS, so this is a lightweight alternative
/// using WKWebView for basic web content display and JavaScript communication
public class FlowsBridgeViewControllerMac: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    private var configuration: WKWebViewConfiguration!
    
    public override func loadView() {
        // Create configuration
        configuration = WKWebViewConfiguration()
        
        // Set Thepia application name for user agent
        configuration.applicationNameForUserAgent = "Thepia/1.0"
        
        // Setup message handler for JavaScript communication
        let contentController = WKUserContentController()
        contentController.add(self, name: "bridge")
        
        // Register dynamic handlers
        if let handlers = config?.messageHandlers {
            for (name, handler) in handlers {
                contentController.add(ClosureScriptHandler(handler: handler), name: name)
            }
        }
        
        // Add user scripts
        if let scripts = config?.userScripts {
            for script in scripts {
                contentController.addUserScript(script)
            }
        }
        
        configuration.userContentController = contentController
        
        // Setup data store
        // Setup data store
        // Use default persistent data store
        let wkDataStore = WKWebsiteDataStore.default()
        
        // Clear cache for specific domains to ensure fresh data
        WebContentManager.shared.clearWebViewCache(for: ["api.thepia.com"])
        
        // Seed cookies from shared storage
        WebContentManager.shared.seedCookies()
        
        configuration.websiteDataStore = wkDataStore
        
        // Create webview
        let frameWithInsetErrorFix = CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1)
        webView = WKWebView(frame: frameWithInsetErrorFix, configuration: configuration)
        webView.navigationDelegate = self
        webView.makeTransparentOnInit()
        
        self.view = webView
    }
    
    public var config: WebAppConfig?

    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.makeTransparentOnViewDidLoad()
        
        if let startURL = config?.startURL {
            print("Loading startURL: \(startURL.absoluteString)")
            if startURL.isFileURL {
                webView.loadFileURL(startURL, allowingReadAccessTo: startURL.deletingLastPathComponent())
            } else {
                webView.load(URLRequest(url: startURL))
            }
        } else {
            // Check if we need to seed from bundle
            if !WebContentManager.shared.hasContent() {
                _ = WebContentManager.shared.seedFromBundle()
            }
            
            if let indexURL = WebContentManager.shared.indexURL, WebContentManager.shared.hasContent() {
            print("Loading local content from: \(indexURL.path)")
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        } else {
            print("No local content found at \(WebContentManager.shared.indexURL?.path ?? "nil")")
        }
        }
    }
    
    // MARK: - WKScriptMessageHandler
    
    /// Handle messages from JavaScript
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle JavaScript messages here
        // Example: message.body contains the data sent from JavaScript
        print("Received message from JavaScript: \(message.body)")
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Page loaded
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
    }
}

#endif

