//
//  FlowsBridgeViewController.swift
//
//  Created by Henrik Vendelbo on 01.07.23.
//

#if canImport(UIKit)

import UIKit
import Capacitor

// TODO move to better location
extension ProcessInfo {
  static public var isSwiftUIPreview: Bool {
          // Checking for the Preview Agent environment variable
          #if DEBUG
          return processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
          #else
          return false
          #endif
      }
}

public class FlowsBridgeViewController: CAPBridgeViewController {

    public var config: WebAppConfig?

    public override func viewDidLoad() {
        // Check if we can safely initialize Capacitor
        // When app extensions are present, iOS may block sandbox extension creation
        let bundlePath = Bundle.main.bundlePath
        let plugInsPath = (bundlePath as NSString).appendingPathComponent("PlugIns")
        
        if FileManager.default.fileExists(atPath: plugInsPath) {
            print("⚠️ WARNING: App extensions detected in bundle. Capacitor may fail due to sandbox restrictions.")
            print("⚠️ If you see 'Could not create a sandbox extension' errors, this is the cause.")
            // We'll try to continue, but Capacitor might fail during resource loading
        }
        
        super.viewDidLoad()

        view.backgroundColor = .clear
        webView!.makeTransparentOnViewDidLoad()
        
        if let startURL = config?.startURL {
            print("Loading startURL: \(startURL.absoluteString)")
            if startURL.isFileURL {
                webView?.loadFileURL(startURL, allowingReadAccessTo: startURL.deletingLastPathComponent())
            } else {
                webView?.load(URLRequest(url: startURL))
            }
        } else {
            // Check if we need to seed from bundle
          // TODO add offline-cache.zip support with feature flag
//            if !WebContentManager.shared.hasContent() {
//                _ = WebContentManager.shared.seedFromBundle()
//            }
            
            if let indexURL = WebContentManager.shared.indexURL, WebContentManager.shared.hasContent() {
            // Load local content
            print("Loading local content from: \(indexURL.path)")
            webView?.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        } else {
            print("No local content found at \(WebContentManager.shared.indexURL?.path ?? "nil")")
            // Fallback to default Capacitor behavior (loading from bundle) is handled by super.viewDidLoad() 
            // but we might want to ensure we don't double load if we found local content.
            // However, CAPBridgeViewController loads in its viewDidLoad. 
            // If we load here, we are just overriding the navigation.
        }
        }
    }
    
    // Forward secrecy certs required: https://stackoverflow.com/questions/71678158/didfailprovisionalloadforframe-for-certain-url-but-works-fine-in-safari

    // MARK: - Construct WebView

    public override func webView(with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
      
      if !ProcessInfo.isSwiftUIPreview {
        // TODO put the store back for better autosuggest!
        
        // Attempting to fix DiskCookieStorage changing policy from 2 to 0
        // Use default persistent data store
        let wkDataStore = WKWebsiteDataStore.default()
        
        // Seed cookies from shared storage
        WebContentManager.shared.seedCookies()
        
        configuration.websiteDataStore = wkDataStore
      } else {
        print("PREVIEW MODE: Skipping complex cookie setup for stability.")
      }
      
      // Register dynamic message handlers
      var handlers = config?.messageHandlers ?? [:]
      
      // Default/Mixin: If 'thepia' handler is not provided but authHandler is, add default ThepiaMessageHandler
      if handlers["thepia"] == nil, let authHandler = config?.authHandler {
          handlers["thepia"] = ThepiaMessageHandler(authHandler: authHandler)
      }
      
      for (name, handler) in handlers {
          configuration.userContentController.add(handler, name: name)
      }
      
      // Add user scripts
      if let scripts = config?.userScripts {
          for script in scripts {
              configuration.userContentController.addUserScript(script)
          }
      }
      
      
//        configuration.websiteDataStore.httpCookieStore
//        configuration.setcookiePolicy
        let frameWithInsetErrorFix = CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1)
        let webView = WKWebView(frame: frameWithInsetErrorFix, configuration: configuration)
        webView.makeTransparentOnInit()
        return webView
    }    

    // MARK: - Navigation
    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

#endif
