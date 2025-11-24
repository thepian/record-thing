import Foundation
import WebKit

public struct WebAppConfig {
    public var startURL: URL?
    public var messageHandlers: [String: (Any) -> Void]
    public var userScripts: [WKUserScript]
    public var initialPageHeight: WebAppPageHeight
    public var backgroundMaterial: WebAppBackgroundMaterial
    
    public static let defaultCSSScript = WKUserScript(source: """
        document.documentElement.style.setProperty('--app-bg', 'transparent');
        document.documentElement.style.setProperty('--app-chrome', 'none');
        document.documentElement.classList.add('webview-mode');
        
        // Force transparency
        document.documentElement.style.backgroundColor = 'transparent';
        document.body.style.backgroundColor = 'transparent';
    """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    
    public init(startURL: URL? = nil, 
                messageHandlers: [String: (Any) -> Void] = [:], 
                userScripts: [WKUserScript] = [WebAppConfig.defaultCSSScript],
                initialPageHeight: WebAppPageHeight = .sheet,
                backgroundMaterial: WebAppBackgroundMaterial = .thinMaterial) {
        self.startURL = startURL
        self.messageHandlers = messageHandlers
        self.userScripts = userScripts
        self.initialPageHeight = initialPageHeight
        self.backgroundMaterial = backgroundMaterial
    }
    
    // MARK: - Builder Pattern
    
    public func startURL(_ url: URL?) -> WebAppConfig {
        var copy = self
        copy.startURL = url
        return copy
    }
    
    public func messageHandler(_ name: String, handler: @escaping (Any) -> Void) -> WebAppConfig {
        var copy = self
        copy.messageHandlers[name] = handler
        return copy
    }
    
    public func userScript(_ script: WKUserScript) -> WebAppConfig {
        var copy = self
        copy.userScripts.append(script)
        return copy
    }
    
    public func initialPageHeight(_ height: WebAppPageHeight) -> WebAppConfig {
        var copy = self
        copy.initialPageHeight = height
        return copy
    }
    
    public func backgroundMaterial(_ material: WebAppBackgroundMaterial) -> WebAppConfig {
        var copy = self
        copy.backgroundMaterial = material
        return copy
    }
}

public class ClosureScriptHandler: NSObject, WKScriptMessageHandler {
    private let handler: (Any) -> Void
    
    public init(handler: @escaping (Any) -> Void) {
        self.handler = handler
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler(message.body)
    }
}
