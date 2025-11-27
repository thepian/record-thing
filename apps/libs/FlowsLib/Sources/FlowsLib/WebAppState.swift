import SwiftUI
import Combine

public enum WebAppReadiness: String, Codable {
    case loading
    case ready
    case transitioning
    case transitioned
    case completed
}

public enum WebAppPageHeight: String, Codable {
    case pill
    case sheet
    case full
}

public enum WebAppBackgroundMaterial: String, Codable {
    case clear
    case thinMaterial
    case ultraThinMaterial
    case regularMaterial
    case thickMaterial
}

public class WebAppState: ObservableObject {
    @Published public var readiness: WebAppReadiness = .loading
    @Published public var pageHeight: WebAppPageHeight = .sheet
    @Published public var backgroundMaterial: WebAppBackgroundMaterial = .thinMaterial
    @Published public var currentStep: String?
    @Published public var stepList: [String] = []
    @Published public var hasBackWithName: String?
    
    public init(initialPageHeight: WebAppPageHeight = .sheet, 
                initialReadiness: WebAppReadiness = .loading,
                initialBackgroundMaterial: WebAppBackgroundMaterial = .thinMaterial) {
        self.pageHeight = initialPageHeight
        self.readiness = initialReadiness
        self.backgroundMaterial = initialBackgroundMaterial
    }
    
    public func handleMessage(_ message: [String: Any]) {
        DispatchQueue.main.async {
            // Support both flat message and nested 'payload'
            let data = message["payload"] as? [String: Any] ?? message
            
            if let readinessString = data["readiness"] as? String,
               let readiness = WebAppReadiness(rawValue: readinessString) {
                self.readiness = readiness
            } else if let typeString = data["type"] as? String, 
                      let readiness = WebAppReadiness(rawValue: typeString) {
                // Legacy support: 'type' used to be used for readiness
                self.readiness = readiness
            }
            
            if let heightString = data["pageHeight"] as? String,
               let height = WebAppPageHeight(rawValue: heightString) {
                self.pageHeight = height
            }
            
            if let materialString = data["backgroundMaterial"] as? String,
               let material = WebAppBackgroundMaterial(rawValue: materialString) {
                self.backgroundMaterial = material
            }
            
            if let step = data["currentStep"] as? String {
                self.currentStep = step
            }
            
            if let steps = data["stepList"] as? [String] {
                self.stepList = steps
            }
            
            if let backName = data["backName"] as? String {
                self.hasBackWithName = backName
            } else if data["backName"] != nil {
                // Explicit null/nil means clear it
                self.hasBackWithName = nil
            }
        }
    }
}

public extension Notification.Name {
    static let WebAppStateUpdated = Notification.Name("WebAppStateUpdated")
}
