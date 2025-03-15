import SwiftUI
import os

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A type alias for platform-specific image types.
///
/// This type alias provides a unified way to work with images across different Apple platforms:
/// - On iOS, iPadOS, tvOS, and watchOS, it maps to UIImage from UIKit
/// - On macOS, it maps to NSImage from AppKit
///
/// Using this type alias allows for cross-platform code that works with images without
/// conditional compilation directives throughout the codebase.
///
/// Example usage:
/// ```swift
/// func processImage(_ image: RecordImage) {
///     // Process the image regardless of platform
///     let size = image.size
///     // ...
/// }
/// ```
#if canImport(UIKit)
public typealias RecordImage = UIImage
#elseif canImport(AppKit)
public typealias RecordImage = NSImage
#endif

/// Extension to provide common functionality across UIImage and NSImage
public extension RecordImage {
    /// Creates a SwiftUI Image from the platform-specific image type
    var asImage: Image {
        #if canImport(UIKit)
        return Image(uiImage: self)
        #elseif canImport(AppKit)
        return Image(nsImage: self)
        #endif
    }
    
    /// Creates a platform-specific image from a SwiftUI Image
    /// Note: This is a placeholder as direct conversion from SwiftUI Image is not straightforward
    /// and would require rendering the SwiftUI Image to a context
    static func fromSwiftUIImage(_ image: Image) -> RecordImage? {
        // This would require a more complex implementation to render the SwiftUI Image
        // For now, return nil as a placeholder
        return nil
    }
    
    /// Creates a platform-specific image from a system name (SF Symbol)
    static func systemImage(_ name: String) -> RecordImage? {
        #if canImport(UIKit)
        return UIImage(systemName: name)
        #elseif canImport(AppKit)
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: name, accessibilityDescription: nil)
        } else {
            return nil
        }
        #endif
    }
    
    /// Converts the image to JPEG data with the specified compression quality
    /// - Parameter compressionQuality: The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0
    /// - Returns: JPEG data representation of the image, or nil if conversion failed
    func jpegData(compressionQuality: CGFloat) -> Data? {
        #if canImport(UIKit)
        // UIImage has a built-in jpegData method
        return self.jpegData(compressionQuality: compressionQuality)
        #elseif canImport(AppKit)
        // For NSImage, we need to convert to a bitmap representation first
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            imageLogger.error("Failed to create bitmap representation from NSImage")
            return nil
        }
        
        // Convert to JPEG with the specified compression quality
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }
}

// MARK: - Debugging

/// Logger for image-related operations
private let imageLogger = Logger(subsystem: "com.record-thing", category: "image")

/// Extension to add debugging helpers
public extension RecordImage {
    /// Logs basic information about the image
    func logInfo(label: String = "") {
        #if canImport(UIKit)
        imageLogger.debug("\(label) UIImage: size=\(self.size.width)x\(self.size.height), scale=\(self.scale)")
        #elseif canImport(AppKit)
        imageLogger.debug("\(label) NSImage: size=\(self.size.width)x\(self.size.height)")
        #endif
    }
}
