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
            if let typeString = message["type"] as? String,
               let readiness = WebAppReadiness(rawValue: typeString) {
                self.readiness = readiness
            }
            
            if let heightString = message["pageHeight"] as? String,
               let height = WebAppPageHeight(rawValue: heightString) {
                self.pageHeight = height
            }
            
            if let materialString = message["backgroundMaterial"] as? String,
               let material = WebAppBackgroundMaterial(rawValue: materialString) {
                self.backgroundMaterial = material
            }
            
            if let step = message["currentStep"] as? String {
                self.currentStep = step
            }
            
            if let steps = message["stepList"] as? [String] {
                self.stepList = steps
            }
            
            if let backName = message["backName"] as? String {
                self.hasBackWithName = backName
            } else if message["backName"] != nil {
                // Explicit null/nil means clear it
                self.hasBackWithName = nil
            }
        }
    }
}
