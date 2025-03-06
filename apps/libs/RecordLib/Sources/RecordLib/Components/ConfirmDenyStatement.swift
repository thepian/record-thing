//
//  ConfirmDenyStatement.swift
//  RecordLib
//
//  Created by Cline on 09.03.2025.
//

import SwiftUI

import UIKit

/// A simple component that displays an object name with thumbs up/down buttons
/// This matches the design shown in "First Scan - iPhone 13 mini.png"
public struct SimpleConfirmDenyStatement: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "SimpleConfirmDenyStatement")
    
    // Properties
    private let objectName: String
    private let onConfirm: () -> Void
    private let onDeny: () -> Void
    private let textColor: Color?
    private let backgroundImage: UIImage?
    private let backgroundBrightness: CGFloat?
    private let useGlowEffect: Bool
    private let glowColor: Color
    private let glowRadius: CGFloat
    private let glowOpacity: Double
    
    // State for dynamic text color
    @State private var dynamicTextColor: Color = .white
    
    /// Creates a new SimpleConfirmDenyStatement with enhanced readability for camera backgrounds
    /// - Parameters:
    ///   - objectName: The name of the detected object
    ///   - textColor: Optional fixed color of the object name text (if nil, color will be determined dynamically)
    ///   - backgroundImage: Optional UIImage to analyze for determining optimal text color
    ///   - backgroundBrightness: Optional brightness value (0-1) to determine text color (if backgroundImage not provided)
    ///   - useGlowEffect: Whether to apply a glow effect to the text for better contrast
    ///   - glowColor: Color of the glow effect (defaults to black)
    ///   - glowRadius: Radius of the glow effect (defaults to 3)
    ///   - glowOpacity: Opacity of the glow effect (defaults to 0.6)
    ///   - onConfirm: Action to perform when the confirm button is tapped
    ///   - onDeny: Action to perform when the deny button is tapped
    public init(
        objectName: String,
        textColor: Color? = nil,
        backgroundImage: UIImage? = nil,
        backgroundBrightness: CGFloat? = nil,
        useGlowEffect: Bool = true,
        glowColor: Color = .black,
        glowRadius: CGFloat = 3,
        glowOpacity: Double = 0.6,
        onConfirm: @escaping () -> Void,
        onDeny: @escaping () -> Void
    ) {
        self.objectName = objectName
        self.textColor = textColor
        self.backgroundImage = backgroundImage
        self.backgroundBrightness = backgroundBrightness
        self.useGlowEffect = useGlowEffect
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.glowOpacity = glowOpacity
        self.onConfirm = onConfirm
        self.onDeny = onDeny
        
        logger.debug("SimpleConfirmDenyStatement initialized for object: \(objectName)")
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                // Deny button (thumbs down)
                Button(action: {
                    logger.debug("Deny button tapped for object: \(objectName)")
                    onDeny()
                }) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
                        .padding(.top, 8)
                }
                .accessibilityLabel("Not a \(objectName)")
                
                // Confirm button (thumbs up)
                Button(action: {
                    logger.debug("Confirm button tapped for object: \(objectName)")
                    onConfirm()
                }) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
                        .padding(.bottom, 8)
                }
                .accessibilityLabel("Yes, it's a \(objectName)")
            }
            // Object name with glow effect
            Text(objectName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(textColor ?? dynamicTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: useGlowEffect ? glowColor.opacity(glowOpacity) : .clear,
                        radius: glowRadius,
                        x: 0,
                        y: 0)
                .onAppear {
                    if textColor == nil {
                        updateDynamicTextColor()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Private Methods
    
    /// Updates the dynamic text color based on background image or brightness
    private func updateDynamicTextColor() {
        // If we have a background image, analyze it to determine text color
        if let image = backgroundImage {
            let brightness = calculateAverageBrightness(from: image)
            dynamicTextColor = brightness > 0.5 ? .black : .white
            logger.debug("Calculated brightness: \(brightness), using \(brightness > 0.5 ? "black" : "white") text")
        } 
        // If we have a brightness value, use that
        else if let brightness = backgroundBrightness {
            dynamicTextColor = brightness > 0.5 ? .black : .white
            logger.debug("Using provided brightness: \(brightness), using \(brightness > 0.5 ? "black" : "white") text")
        }
        // Default to white text if no background info is provided
        else {
            dynamicTextColor = .white
            logger.debug("No background info provided, defaulting to white text")
        }
    }
    
    /// Calculates the average brightness of an image
    /// - Parameter image: The UIImage to analyze
    /// - Returns: A value between 0 (dark) and 1 (bright)
    private func calculateAverageBrightness(from image: UIImage) -> CGFloat {
        guard let cgImage = image.cgImage else { return 0.5 }
        
        // Create a bitmap context to sample pixels
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let totalBytes = bytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapData = [UInt8](repeating: 0, count: totalBytes)
        
        guard let context = CGContext(
            data: &bitmapData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0.5 }
        
        // Draw the image into the context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // Sample pixels (take a subset for performance)
        var totalBrightness: CGFloat = 0
        var sampleCount = 0
        let sampleEvery = max(1, width * height / 1000) // Sample at most 1000 pixels
        
        for y in stride(from: 0, to: height, by: sampleEvery) {
            for x in stride(from: 0, to: width, by: sampleEvery) {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = CGFloat(bitmapData[offset]) / 255.0
                let g = CGFloat(bitmapData[offset + 1]) / 255.0
                let b = CGFloat(bitmapData[offset + 2]) / 255.0
                
                // Calculate perceived brightness using luminance formula
                let brightness = (0.299 * r) + (0.587 * g) + (0.114 * b)
                totalBrightness += brightness
                sampleCount += 1
            }
        }
        
        return sampleCount > 0 ? totalBrightness / CGFloat(sampleCount) : 0.5
    }
}

/// A view modifier that adds a glow effect to text
public struct TextGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let opacity: Double
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}

/// Extension to add the glow modifier to any view
public extension View {
    /// Adds a glow effect to the view
    /// - Parameters:
    ///   - color: The color of the glow
    ///   - radius: The radius of the glow
    ///   - opacity: The opacity of the glow
    /// - Returns: A view with the glow effect applied
    func glow(color: Color = .black, radius: CGFloat = 3, opacity: Double = 0.6) -> some View {
        self.modifier(TextGlowModifier(color: color, radius: radius, opacity: opacity))
    }
}


/// A component that displays a statement with confirm and deny buttons for validating camera object detection
public struct ConfirmDenyStatement: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "ConfirmDenyStatement")
    
    // Properties
    private let statement: String
    private let objectName: String
    private let objectImage: Image?
    private let onConfirm: () -> Void
    private let onDeny: () -> Void
    private let confirmText: String
    private let denyText: String
    private let backgroundColor: Color
    private let textColor: Color
    private let buttonBackgroundColor: Color
    private let buttonTextColor: Color
    private let cornerRadius: CGFloat
    
    /// Creates a new ConfirmDenyStatement with custom appearance
    /// - Parameters:
    ///   - statement: The statement or question to display
    ///   - objectName: The name of the detected object
    ///   - objectImage: Optional image representing the object
    ///   - confirmText: Text for the confirm button
    ///   - denyText: Text for the deny button
    ///   - backgroundColor: Background color of the component
    ///   - textColor: Color of the statement text
    ///   - buttonBackgroundColor: Background color of the buttons
    ///   - buttonTextColor: Text color of the buttons
    ///   - cornerRadius: Corner radius of the component
    ///   - onConfirm: Action to perform when the confirm button is tapped
    ///   - onDeny: Action to perform when the deny button is tapped
    public init(
        statement: String = "Is this a",
        objectName: String,
        objectImage: Image? = nil,
        confirmText: String = "Yes",
        denyText: String = "No",
        backgroundColor: Color = Color(.secondarySystemBackground),
        textColor: Color = .primary,
        buttonBackgroundColor: Color = .blue,
        buttonTextColor: Color = .white,
        cornerRadius: CGFloat = 16,
        onConfirm: @escaping () -> Void,
        onDeny: @escaping () -> Void
    ) {
        self.statement = statement
        self.objectName = objectName
        self.objectImage = objectImage
        self.confirmText = confirmText
        self.denyText = denyText
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonTextColor = buttonTextColor
        self.cornerRadius = cornerRadius
        self.onConfirm = onConfirm
        self.onDeny = onDeny
        
        logger.debug("ConfirmDenyStatement initialized for object: \(objectName)")
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Statement and object name
            VStack(spacing: 8) {
                Text(statement)
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Text(objectName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
            }
            .padding(.top, 8)
            
            // Optional object image
            if let objectImage = objectImage {
                objectImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Confirm/Deny buttons
            HStack(spacing: 16) {
                // Deny button
                Button(action: {
                    logger.debug("Deny button tapped for object: \(objectName)")
                    onDeny()
                }) {
                    Text(denyText)
                        .font(.headline)
                        .foregroundColor(buttonTextColor)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(buttonBackgroundColor.opacity(0.7))
                        .cornerRadius(cornerRadius / 2)
                }
                .accessibilityLabel("Deny \(objectName)")
                
                // Confirm button
                Button(action: {
                    logger.debug("Confirm button tapped for object: \(objectName)")
                    onConfirm()
                }) {
                    Text(confirmText)
                        .font(.headline)
                        .foregroundColor(buttonTextColor)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(buttonBackgroundColor)
                        .cornerRadius(cornerRadius / 2)
                }
                .accessibilityLabel("Confirm \(objectName)")
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

/// A simplified version of ConfirmDenyStatement with a more compact layout
public struct CompactConfirmDenyStatement: View {
    // Properties
    private let objectName: String
    private let onConfirm: () -> Void
    private let onDeny: () -> Void
    
    /// Creates a new CompactConfirmDenyStatement
    /// - Parameters:
    ///   - objectName: The name of the detected object
    ///   - onConfirm: Action to perform when the confirm button is tapped
    ///   - onDeny: Action to perform when the deny button is tapped
    public init(
        objectName: String,
        onConfirm: @escaping () -> Void,
        onDeny: @escaping () -> Void
    ) {
        self.objectName = objectName
        self.onConfirm = onConfirm
        self.onDeny = onDeny
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Question text
            Text("Is this a \(objectName)?")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Deny button
            Button(action: onDeny) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red)
            }
            .accessibilityLabel("Not a \(objectName)")
            
            // Confirm button
            Button(action: onConfirm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            .accessibilityLabel("Yes, it's a \(objectName)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
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
struct ConfirmDenyStatement_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    Text("SimpleConfirmDenyStatement Examples")
                        .font(.headline)
                        .padding(.top)
                    
                    // Dark background with glow (default)
                    ZStack {
                        Color.black // Dark background
                        
                        SimpleConfirmDenyStatement(
                            objectName: "Electric Mountain Bike",
                            onConfirm: { print("Confirmed electric mountain bike") },
                            onDeny: { print("Denied electric mountain bike") }
                        )
                        .padding()
                    }
                    .frame(height: 100)
                    .cornerRadius(12)
                    .overlay(
                        Text("Default (white text with dark glow)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4),
                        alignment: .top
                    )
                    
                    // Light background with auto text color
                    ZStack {
                        Color.white // Light background
                        
                        SimpleConfirmDenyStatement(
                            objectName: "Receipt Scanner",
                            backgroundBrightness: 0.9, // Bright background
                            glowColor: .white, // Light glow for dark text
                            onConfirm: { print("Confirmed receipt scanner") },
                            onDeny: { print("Denied receipt scanner") }
                        )
                        .padding()
                    }
                    .frame(height: 100)
                    .cornerRadius(12)
                    .overlay(
                        Text("Light background (auto black text)")
                            .font(.caption2)
                            .foregroundColor(.black)
                            .padding(4)
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(4),
                        alignment: .top
                    )
                    
                    // Mixed background with stronger glow
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        SimpleConfirmDenyStatement(
                            objectName: "Product Label",
                            textColor: .white, // Force white text
                            glowRadius: 5, // Stronger glow
                            glowOpacity: 0.8, // More opaque
                            onConfirm: { print("Confirmed product label") },
                            onDeny: { print("Denied product label") }
                        )
                        .padding()
                    }
                    .frame(height: 100)
                    .cornerRadius(12)
                    .overlay(
                        Text("Gradient background (stronger glow)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4),
                        alignment: .top
                    )
                    
                    // No glow example
                    ZStack {
                        Color.gray.opacity(0.3) // Light gray background
                        
                        SimpleConfirmDenyStatement(
                            objectName: "Barcode",
                            textColor: .black,
                            useGlowEffect: false, // No glow
                            onConfirm: { print("Confirmed barcode") },
                            onDeny: { print("Denied barcode") }
                        )
                        .padding()
                    }
                    .frame(height: 100)
                    .cornerRadius(12)
                    .overlay(
                        Text("No glow effect")
                            .font(.caption2)
                            .foregroundColor(.black)
                            .padding(4)
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(4),
                        alignment: .top
                    )
                }
                
                Divider()
                    .padding(.vertical)
                
                Group {
                    Text("Other Component Variants")
                        .font(.headline)
                    
                    // Standard version
                    ConfirmDenyStatement(
                        statement: "Is this a",
                        objectName: "Receipt",
                        confirmText: "Yes, it is",
                        denyText: "No, it's not",
                        onConfirm: { print("Confirmed receipt") },
                        onDeny: { print("Denied receipt") }
                    )
                    .padding()
                    
                    // With custom colors
                    ConfirmDenyStatement(
                        statement: "Did you find a",
                        objectName: "Product Label",
                        backgroundColor: Color.black.opacity(0.8),
                        textColor: .white,
                        buttonBackgroundColor: .green,
                        onConfirm: { print("Confirmed product label") },
                        onDeny: { print("Denied product label") }
                    )
                    .padding()
                    
                    // Compact version
                    CompactConfirmDenyStatement(
                        objectName: "Barcode",
                        onConfirm: { print("Confirmed barcode") },
                        onDeny: { print("Denied barcode") }
                    )
                    .padding()
                }
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
        .background(Color(.systemBackground))
    }
}
