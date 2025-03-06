//
//  ConfirmDenyStatementDemo.swift
//  RecordLib
//
//  Created by Cline on 09.03.2025.
//

import SwiftUI

/// A demonstration view showing how to use the ConfirmDenyStatement component in a camera context
public struct ConfirmDenyStatementDemo: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "ConfirmDenyStatementDemo")
    
    // State for the demo
    @State private var showConfirmation: Bool = true
    @State private var detectedObject: String = "Receipt"
    @State private var confirmationCount: Int = 0
    @State private var denialCount: Int = 0
    @State private var displayMode: DisplayMode = .simple // Default to simple mode to match the screenshot
    
    // Display modes for the demo
    private enum DisplayMode: String, CaseIterable {
        case simple = "Simple"
        case standard = "Standard"
        case compact = "Compact"
    }
    
    // Sample objects for demonstration
    private let sampleObjects = ["Receipt", "Product Label", "Barcode", "Price Tag", "Nutrition Facts"]
    
    public init() {
        logger.debug("ConfirmDenyStatementDemo initialized")
    }
    
    public var body: some View {
        ZStack {
            // Mock camera background (would be a real camera feed in the actual app)
            Color.black
                .ignoresSafeArea()
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            VStack {
                // Stats display
                HStack {
                    VStack(alignment: .leading) {
                        Text("Confirmed: \(confirmationCount)")
                            .foregroundColor(.white)
                        Text("Denied: \(denialCount)")
                            .foregroundColor(.white)
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Toggle between display modes
                    Menu {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Button(mode.rawValue) {
                                displayMode = mode
                                logger.debug("Switched to \(mode.rawValue) display mode")
                            }
                        }
                    } label: {
                        HStack {
                            Text(displayMode.rawValue)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
                
                // Show the confirmation component when an object is detected
                if showConfirmation {
                    switch displayMode {
                    case .simple:
                        // Simple version with glow effect for better readability on camera backgrounds
                        SimpleConfirmDenyStatement(
                            objectName: detectedObject,
                            // We're not providing textColor, so it will use dynamic color based on background
                            // In a real app, you could analyze the camera frame to determine brightness
                            backgroundBrightness: 0.2, // Simulate a dark camera background
                            useGlowEffect: true,
                            glowColor: .black,
                            glowRadius: 3,
                            glowOpacity: 0.7,
                            onConfirm: handleConfirm,
                            onDeny: handleDeny
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                    case .standard:
                        // Standard version
                        ConfirmDenyStatement(
                            statement: "Is this a",
                            objectName: detectedObject,
                            confirmText: "Yes, it is",
                            denyText: "No, it's not",
                            backgroundColor: Color.black.opacity(0.7),
                            textColor: .white,
                            buttonBackgroundColor: .blue,
                            onConfirm: handleConfirm,
                            onDeny: handleDeny
                        )
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                    case .compact:
                        // Compact version
                        CompactConfirmDenyStatement(
                            objectName: detectedObject,
                            onConfirm: handleConfirm,
                            onDeny: handleDeny
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                // Camera controls toolbar
                StandardFloatingToolbar(
                    onDataBrowseTapped: { logger.debug("DataBrowse tapped") }, 
                    onStackTapped: { logger.debug("Stack tapped") },
                    onCameraTapped: simulateDetection,
                    onAccountTapped: { logger.debug("Account tapped") }
                )
            }
        }
        .animation(.easeInOut, value: showConfirmation)
        .animation(.easeInOut, value: displayMode)
    }
    
    // MARK: - Actions
    
    /// Handles the confirm action
    private func handleConfirm() {
        logger.debug("Object confirmed: \(detectedObject)")
        confirmationCount += 1
        showConfirmation = false
    }
    
    /// Handles the deny action
    private func handleDeny() {
        logger.debug("Object denied: \(detectedObject)")
        denialCount += 1
        showConfirmation = false
    }
    
    /// Simulates detecting a new object with the camera
    private func simulateDetection() {
        // Hide any current confirmation
        showConfirmation = false
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Select a random object from the sample list
            detectedObject = sampleObjects.randomElement() ?? "Object"
            logger.debug("New object detected: \(detectedObject)")
            
            // Show the confirmation
            showConfirmation = true
        }
    }
}

// Simple logger for debugging
fileprivate struct Logger {
    let subsystem: String
    let category: String
    
    func debug(_ message: String) {
        #if DEBUG
        print("[\(subsystem):\(category)] DEBUG: \(message)")
        #endif
    }
}

// MARK: - Preview
struct ConfirmDenyStatementDemo_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmDenyStatementDemo()
    }
}
