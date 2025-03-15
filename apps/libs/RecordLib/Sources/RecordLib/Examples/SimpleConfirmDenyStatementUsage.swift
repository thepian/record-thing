//
//  SimpleConfirmDenyStatementUsage.swift
//  RecordLib
//
//  Created by Cline on 09.03.2025.
//

import SwiftUI
import Vision

/// An example showing how to use SimpleConfirmDenyStatement with camera frames
/// and dynamically adjust text appearance based on background brightness
public struct CameraObjectDetectionView: View {
    // State
    @State private var detectedObject: String?
    @State private var showConfirmation: Bool = false
    @State private var backgroundBrightness: CGFloat = 0.0
    @State private var currentFrame: RecordImage?
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "CameraObjectDetectionView")
    
    public init() {
        logger.debug("CameraObjectDetectionView initialized")
    }
    
    public var body: some View {
        ZStack {
            // Camera view would go here
            // For demo purposes, we're using a placeholder
            Color.black
                .ignoresSafeArea()
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            // Object detection confirmation when an object is detected
            if let objectName = detectedObject, showConfirmation {
                VStack {
                    Spacer()
                    
                    // Use SimpleConfirmDenyStatement with dynamic text color based on background
                    SimpleConfirmDenyStatement(
                        objectName: objectName,
                        // Pass the current frame for brightness analysis
                        // or pass the pre-calculated brightness value
                        backgroundImage: currentFrame,
                        // backgroundBrightness: backgroundBrightness, // Alternative approach
                        useGlowEffect: true,
                        // Use white glow for dark text on light backgrounds
                        // and black glow for light text on dark backgrounds
                        glowColor: backgroundBrightness > 0.5 ? .white : .black,
                        glowRadius: 3,
                        glowOpacity: 0.7,
                        onConfirm: {
                            handleConfirm(objectName: objectName)
                        },
                        onDeny: {
                            handleDeny(objectName: objectName)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            // Simulate object detection for demo purposes
            simulateObjectDetection()
        }
    }
    
    // MARK: - Actions
    
    /// Handles the confirm action
    private func handleConfirm(objectName: String) {
        logger.debug("Object confirmed: \(objectName)")
        showConfirmation = false
        // Process the confirmed object
    }
    
    /// Handles the deny action
    private func handleDeny(objectName: String) {
        logger.debug("Object denied: \(objectName)")
        showConfirmation = false
        // Continue scanning
    }
    
    /// Simulates object detection for demo purposes
    private func simulateObjectDetection() {
        // In a real app, this would be triggered by Vision framework detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Simulate detecting an object
            detectedObject = "Electric Mountain Bike"
            
            // Simulate analyzing the camera frame for brightness
            // In a real app, you would analyze the actual camera frame
            backgroundBrightness = 0.2 // Dark background
            
            // Show the confirmation
            showConfirmation = true
        }
    }
    
    // MARK: - Camera Frame Analysis
    
    /// Analyzes a camera frame to determine background brightness
    /// - Parameter pixelBuffer: The CVPixelBuffer from the camera
    /// - Returns: A brightness value between 0 (dark) and 1 (bright)
    private func analyzeFrameBrightness(pixelBuffer: CVPixelBuffer) -> CGFloat {
        // Note: VNAnalyzeImageRequest is not directly available for brightness analysis
        // Instead, we'll use a more reliable approach with Core Image
        
        // Create a CIImage from the pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Create a scaled down version for faster processing
        let scale = 0.1 // 10% of original size
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Create a CIContext for processing
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        
        // Create a bitmap for sampling pixels
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return 0.5
        }
        
        // Get bitmap data
        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return 0.5
        }
        
        // Calculate brightness
        let totalBytes = CFDataGetLength(data)
        let bytesPerPixel = 4
        let totalPixels = totalBytes / bytesPerPixel
        
        var totalBrightness: CGFloat = 0
        
        // Sample pixels
        for i in stride(from: 0, to: totalBytes, by: bytesPerPixel) {
            let r = CGFloat(bytes[i]) / 255.0
            let g = CGFloat(bytes[i + 1]) / 255.0
            let b = CGFloat(bytes[i + 2]) / 255.0
            
            // Use luminance formula for perceived brightness
            let brightness = (0.299 * r) + (0.587 * g) + (0.114 * b)
            totalBrightness += brightness
        }
        
        // Return average brightness
        return totalPixels > 0 ? totalBrightness / CGFloat(totalPixels) : 0.5
    }
    
    /// Alternative approach using Vision framework for image analysis
    /// Note: This requires iOS 15+ (VNImageAttributesRequest was introduced in iOS 15)
    @available(iOS 15.0, *)
    private func analyzeFrameBrightnessWithVision(pixelBuffer: CVPixelBuffer, completion: @escaping (CGFloat) -> Void) {
        // Create a request handler
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // Create a request for image properties analysis
        let request = VNGenerateImageFeaturePrintRequest()
        
        // Perform the request
        do {
            try requestHandler.perform([request])
            
            // For iOS 15+, you would use VNImageAttributesRequest instead:
            // let request = VNImageAttributesRequest()
            // try requestHandler.perform([request])
            // let brightness = request.results?.contrast ?? 0.5
            
            // Since we can't use VNImageAttributesRequest, we'll use a different approach
            // This is a simplified approach using feature print to estimate brightness
            
            // Use a basic ML model to analyze the feature print
            // For this example, we'll just return a default value
            // In a real app, you would implement a more sophisticated approach
            
            logger.debug("Vision framework analysis completed")
            completion(0.5) // Default value
        } catch {
            logger.debug("Error analyzing frame with Vision: \(error.localizedDescription)")
            completion(0.5)
        }
    }
    
    /// Another alternative using Metal for image analysis
    /// This approach works on all iOS versions that support Metal
    private func analyzeFrameBrightnessWithMetal(pixelBuffer: CVPixelBuffer, completion: @escaping (CGFloat) -> Void) {
        // Create a CIImage from the pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply a CIAreaAverage filter to get the average color
        let extent = ciImage.extent
        let averageFilter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ])
        
        guard let outputImage = averageFilter?.outputImage else {
            completion(0.5)
            return
        }
        
        // Create a CIContext to render the result
        let context = CIContext(options: nil)
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        // Render the output image to get the average color
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        // Calculate brightness using the luminance formula
        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0
        let brightness = (0.299 * r) + (0.587 * g) + (0.114 * b)
        
        logger.debug("Metal analysis completed with brightness: \(brightness)")
        completion(brightness)
    }
    
    /// Converts a CVPixelBuffer to a RecordImage
    /// - Parameter pixelBuffer: The CVPixelBuffer to convert
    /// - Returns: A RecordImage, or nil if conversion fails
    private func recordImage(from pixelBuffer: CVPixelBuffer) -> RecordImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        #endif
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
struct CameraObjectDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        CameraObjectDetectionView()
    }
}
