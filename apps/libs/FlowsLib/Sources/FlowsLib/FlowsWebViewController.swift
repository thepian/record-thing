//
//  FlowsWebViewController.swift
//  FlowsLib
//
//  Created by Henrik Vendelbo on 21.11.2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
import WebKit

// A simplified view controller that doesn't rely on Capacitor or CAPBridgeViewController
public class FlowsWebViewController: UIViewController {
    public let webView: WKWebView
    public var config: WebAppConfig?

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // Create configuration with Thepia application name
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Thepia/1.0"
        
        // Use default persistent data store
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Create webView with configuration
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        // Create configuration with Thepia application name
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Thepia/1.0"
        
        // Use default persistent data store
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // Create webView with configuration
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init(coder: coder)
    }


    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        webView.makeTransparentOnViewDidLoad()
        webView.navigationDelegate = self
        
        // Enable Web Inspector for debugging (iOS 16.4+, macOS 13.3+)
        #if DEBUG
        if #available(iOS 16.4, macOS 13.3, *) {
            webView.isInspectable = true
        }
        #endif
        
        // Add the WKWebView to the view hierarchy
        view.addSubview(webView)
        // Set constraints...
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Load some safe, simple content for the preview
        // Load content from config if available
        if let startURL = config?.startURL {
            print("FlowsWebViewController: Loading URL: \(startURL)")
            if startURL.isFileURL {
                webView.loadFileURL(startURL, allowingReadAccessTo: startURL.deletingLastPathComponent())
            } else {
                webView.load(URLRequest(url: startURL))
            }
        } else if let url = URL(string: "https://www.apple.com/feed/") {
             print("FlowsWebViewController: Loading fallback URL")
             webView.load(URLRequest(url: url))
        } else {
             print("FlowsWebViewController: No URL to load")
        }
        
        // Register message handlers
        if let handlers = config?.messageHandlers {
            for (name, handler) in handlers {
                webView.configuration.userContentController.add(ClosureScriptHandler(handler: handler), name: name)
            }
        }
        
        // Add user scripts
        if let scripts = config?.userScripts {
            for script in scripts {
                webView.configuration.userContentController.addUserScript(script)
            }
        }
    }
}

extension FlowsWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("FlowsWebViewController: Started provisional navigation")
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("FlowsWebViewController: Finished navigation")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("FlowsWebViewController: Failed provisional navigation: \(error.localizedDescription)")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("FlowsWebViewController: Failed navigation: \(error.localizedDescription)")
    }
}
#endif

