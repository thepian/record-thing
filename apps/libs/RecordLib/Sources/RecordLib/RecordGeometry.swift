//
//  RecordGeometry.swift
//  RecordLib
//
//  Created by AI Assistant on 08.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
import SwiftUI
import os

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A cross-platform type alias for specifying which corners of a rectangle should be rounded.
///
/// This type provides a unified way to work with corner specifications across different Apple platforms:
/// - On iOS, iPadOS, tvOS, and watchOS, it maps to UIRectCorner from UIKit
/// - On macOS, it provides a custom OptionSet that mimics UIRectCorner behavior
///
/// Using this type alias allows for cross-platform code that specifies corner rounding without
/// conditional compilation directives throughout the codebase.
///
/// Example usage:
/// ```swift
/// func roundCorners(_ corners: RecordRectCorner) {
///     // Round the specified corners regardless of platform
/// }
/// ```
#if canImport(UIKit)
public typealias RecordRectCorner = UIRectCorner
#else
/// macOS-specific implementation of corner specification
public struct RecordRectCorner: OptionSet, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let topLeft = RecordRectCorner(rawValue: 1 << 0)
    public static let topRight = RecordRectCorner(rawValue: 1 << 1)
    public static let bottomLeft = RecordRectCorner(rawValue: 1 << 2)
    public static let bottomRight = RecordRectCorner(rawValue: 1 << 3)
    public static let allCorners: RecordRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}
#endif

/// Extension to provide SwiftUI-compatible functionality across platforms
public extension RecordRectCorner {
    /// Convert to a SwiftUI corner set for better API integration
    var cornerSet: Set<String> {
        var corners: Set<String> = []
        
        if self.contains(.topLeft) { corners.insert("topLeading") }
        if self.contains(.topRight) { corners.insert("topTrailing") }
        if self.contains(.bottomLeft) { corners.insert("bottomLeading") }
        if self.contains(.bottomRight) { corners.insert("bottomTrailing") }
        
        return corners
    }
}

/// Cross-platform shape for rounding specific corners
public struct RecordRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RecordRectCorner = .allCorners

    public init(radius: CGFloat, corners: RecordRectCorner) {
        self.radius = radius
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        #if canImport(UIKit)
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
        #else
        // macOS/AppKit implementation
        let path = NSBezierPath()
        
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        
        let topLeftRadius = corners.contains(.topLeft) ? radius : 0
        let topRightRadius = corners.contains(.topRight) ? radius : 0
        let bottomLeftRadius = corners.contains(.bottomLeft) ? radius : 0
        let bottomRightRadius = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: NSPoint(x: minX + topLeftRadius, y: minY))
        
        // Top edge
        path.line(to: NSPoint(x: maxX - topRightRadius, y: minY))
        
        // Top right corner
        if topRightRadius > 0 {
            path.appendArc(withCenter: NSPoint(x: maxX - topRightRadius, y: minY + topRightRadius),
                          radius: topRightRadius,
                          startAngle: -90 * .pi / 180,
                          endAngle: 0 * .pi / 180)
        }
        
        // Right edge
        path.line(to: NSPoint(x: maxX, y: maxY - bottomRightRadius))
        
        // Bottom right corner
        if bottomRightRadius > 0 {
            path.appendArc(withCenter: NSPoint(x: maxX - bottomRightRadius, y: maxY - bottomRightRadius),
                          radius: bottomRightRadius,
                          startAngle: 0 * .pi / 180,
                          endAngle: 90 * .pi / 180)
        }
        
        // Bottom edge
        path.line(to: NSPoint(x: minX + bottomLeftRadius, y: maxY))
        
        // Bottom left corner
        if bottomLeftRadius > 0 {
            path.appendArc(withCenter: NSPoint(x: minX + bottomLeftRadius, y: maxY - bottomLeftRadius),
                          radius: bottomLeftRadius,
                          startAngle: 90 * .pi / 180,
                          endAngle: 180 * .pi / 180)
        }
        
        // Left edge
        path.line(to: NSPoint(x: minX, y: minY + topLeftRadius))
        
        // Top left corner
        if topLeftRadius > 0 {
            path.appendArc(withCenter: NSPoint(x: minX + topLeftRadius, y: minY + topLeftRadius),
                          radius: topLeftRadius,
                          startAngle: 180 * .pi / 180,
                          endAngle: 270 * .pi / 180)
        }
        
        path.close()
        return Path(path.cgPath)
        #endif
    }
}

// MARK: - SwiftUI Extensions

public extension View {
    /// Apply corner radius to specific corners using cross-platform RecordRectCorner
    /// This provides a cross-platform alternative to the existing UIRectCorner-based function
    func cornerRadius(_ radius: CGFloat, recordCorners: RecordRectCorner) -> some View {
        clipShape(RecordRoundedCorner(radius: radius, corners: recordCorners))
    }
}

// MARK: - Debugging

/// Logger for geometry-related operations
private let geometryLogger = Logger(subsystem: "com.record-thing", category: "geometry")

/// Extension to add debugging helpers
public extension RecordRectCorner {
    /// Logs information about the corner specification
    func logInfo(label: String = "") {
        var cornersDescription: [String] = []
        
        if self.contains(.topLeft) { cornersDescription.append("topLeft") }
        if self.contains(.topRight) { cornersDescription.append("topRight") }
        if self.contains(.bottomLeft) { cornersDescription.append("bottomLeft") }
        if self.contains(.bottomRight) { cornersDescription.append("bottomRight") }
        
        geometryLogger.debug("\(label) RecordRectCorner: \(cornersDescription.joined(separator: ", "))")
    }
}

#if DEBUG
struct RecordGeometry_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .cornerRadius(20, recordCorners: [.topLeft, .topRight])
            
            Rectangle()
                .fill(Color.green)
                .frame(width: 100, height: 100)
                .cornerRadius(20, recordCorners: .allCorners)
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 100, height: 100)
                .cornerRadius(20, recordCorners: [.bottomLeft, .bottomRight])
        }
        .padding()
        .previewDisplayName("Corner Radius Examples")
    }
}
#endif 