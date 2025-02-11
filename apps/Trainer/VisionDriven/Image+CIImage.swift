//
//  Image+CIImage.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 14.11.2023.
//

import Foundation
import CoreGraphics
import CoreImage
import SwiftUI
import Vision

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
extension CGRect {
    
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
    
    /// Alias for origin.x.
    public var x: CGFloat {
        get {return origin.x}
        set {origin.x = newValue}
    }
    /// Alias for origin.y.
    public var y: CGFloat {
        get {return origin.y}
        set {origin.y = newValue}
    }
    
    // MARK: edges
    
    /// Alias for origin.x.
    public var left: CGFloat {
        get {return origin.x}
        set {origin.x = newValue}
    }
    /// Accesses origin.x + size.width.
    public var right: CGFloat {
        get {return x + width}
        set {x = newValue - width}
    }
    
#if os(iOS)
    /// Alias for origin.y.
    public var top: CGFloat {
        get {return y}
        set {y = newValue}
    }
    /// Accesses origin.y + size.height.
    public var bottom: CGFloat {
        get {return y + height}
        set {y = newValue - height}
    }
#else
    /// Accesses origin.y + size.height.
    public var top: CGFloat {
        get {return y + height}
        set {y = newValue - height}
    }
    /// Alias for origin.y.
    public var bottom: CGFloat {
        get {return y}
        set {y = newValue}
    }
#endif
    
    // MARK: points
    
    
    /// Accesses the point at the top left corner.
    public var topLeft: CGPoint {
        get {return CGPoint(x: left, y: top)}
        set {left = newValue.x; top = newValue.y}
    }
    
    /// Accesses the point at the top right corner.
    public var topRight: CGPoint {
        get {return CGPoint(x: right, y: top)}
        set {right = newValue.x; top = newValue.y}
    }
    
    /// Accesses the point at the bottom left corner.
    public var bottomLeft: CGPoint {
        get {return CGPoint(x: left, y: bottom)}
        set {left = newValue.x; bottom = newValue.y}
    }

    /// Accesses the point at the bottom right corner.
    public var bottomRight: CGPoint {
        get {return CGPoint(x: right, y: bottom)}
        set {right = newValue.x; bottom = newValue.y}
    }
}

public extension Image {

    init(ciImage: CIImage) {

#if canImport(UIKit)
        // Note that making a UIImage and then using that to initialize the Image doesn't seem to work, but CGImage is fine.
        // Possible optimization - store and reuse a CIContext
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            self.init(cgImage, scale: 1.0, orientation: .up, label: Text(""))
        } else {
            self.init(systemName: "unknown")
        }
#elseif canImport(AppKit)
        // Looks like the NSCIImageRep is slightly better optimized for repeated runs,
        // I'm guessing that it doesn't actually render the bitmap unless it needs to.
        let rep = NSCIImageRep(ciImage: ciImage)
        guard rep.size.width <= 10000, rep.size.height <= 10000 else {        // simple test to make sure we don't have overflow extent
            self.init(nsImage: NSImage())
            return
        }
        let nsImage = NSImage(size: rep.size)    // size affects aspect ratio but not resolution
        nsImage.addRepresentation(rep)
        self.init(nsImage: nsImage)
#endif
    }
    
    init(ciImage: CIImage, scale: CGFloat, orientation: Image.Orientation, label: Text) {
#if canImport(UIKit)
        // Note that making a UIImage and then using that to initialize the Image doesn't seem to work, but CGImage is fine.
        // Possible optimization - store and reuse a CIContext
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            self.init(cgImage, scale: scale, orientation: orientation, label: label)
        } else {
            self.init(systemName: "unknown")
        }
#elseif canImport(AppKit)
        // Looks like the NSCIImageRep is slightly better optimized for repeated runs,
        // I'm guessing that it doesn't actually render the bitmap unless it needs to.
        let rep = NSCIImageRep(ciImage: ciImage)
        guard rep.size.width <= 10000, rep.size.height <= 10000 else {        // simple test to make sure we don't have overflow extent
            self.init(nsImage: NSImage())
            return
        }
        let nsImage = NSImage(size: rep.size)    // size affects aspect ratio but not resolution
        nsImage.addRepresentation(rep)
        self.init(nsImage: nsImage)
#endif
    }
}

func perspectiveCorrectedImage(
    from inputImage: CIImage,
    rectangleObservation: VNRectangleObservation
)
-> CIImage? {
    let imageSize = inputImage.extent.size

    // Verify detected rectangle is valid.
    let boundingBox = rectangleObservation.boundingBox.scaled(to: imageSize)
    guard inputImage.extent.contains(boundingBox) else {
        print("invalid detected rectangle")
        return nil
    }
    // Rectify the detected image and reduce it to inverted grayscale for applying model.
    let topLeft = rectangleObservation.topLeft.scaled(to: imageSize)
    let topRight = rectangleObservation.topRight.scaled(to: imageSize)
    let bottomLeft = rectangleObservation.bottomLeft.scaled(to: imageSize)
    let bottomRight = rectangleObservation.bottomRight.scaled(to: imageSize)
    let correctedImage = inputImage
        .cropped(to: boundingBox)
        .applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight)
        ])
    return correctedImage
}

public func createCGPathForTopLeftCCWQuadrilateral(_ topLeft: CGPoint,
                                            _ bottomLeft: CGPoint,
                                            _ bottomRight: CGPoint,
                                            _ topRight: CGPoint,
                                            _ transform: CGAffineTransform) -> CGPath
{
    let path = CGMutablePath()
    path.move(to: topLeft, transform: transform)
    path.addLine(to: bottomLeft, transform: transform)
    path.addLine(to: bottomRight, transform: transform)
    path.addLine(to: topRight, transform: transform)
    path.addLine(to: topLeft, transform: transform)
    path.closeSubpath()
    return path
}

public func ciToCgImage(ciImage: CIImage, ciContext: CIContext) -> CGImage? {
    guard let sourceImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    let size = CGSize(width: sourceImage.width, height: sourceImage.height)
//    let imageSpaceTransform = CGAffineTransform(scaleX:size.width, y:size.height)
    let colorSpace = CGColorSpace.init(name: CGColorSpace.sRGB)
    let cgContext = CGContext.init(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 8 * 4 * Int(size.width), space: colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    cgContext.setStrokeColor(CGColor.init(srgbRed: 0.0,  green: 1.0,  blue: 0.0,  alpha: 0.5))
//    cgContext.setLineWidth(annotationLineWidth)
    cgContext.draw(sourceImage, in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
    
//    for tracked in observedObjects {
//        if let observation = tracked.value.rectObservation {
//            cgContext.setStrokeColor(tracked.value.color.cgColor)
//            let path = createCGPathForTopLeftCCWQuadrilateral(observation.topLeft, observation.bottomLeft, observation.bottomRight, observation.topRight, imageSpaceTransform)
//            cgContext.addPath(path)
//            cgContext.strokePath()
//        }
//    }
    return cgContext.makeImage() ?? sourceImage
}
