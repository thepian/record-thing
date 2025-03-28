//
//  Bundle.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 29.03.2025.
//

import Foundation
import AVFoundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Helper extension to create a sample video file for previews
extension Bundle {
    static func createSampleVideo() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let videoURL = tempDir.appendingPathComponent("sample_video.mp4")
        
        // Create a simple video file if it doesn't exist
        if !FileManager.default.fileExists(atPath: videoURL.path) {
            // Create a video asset with a colored frame
            let composition = AVMutableComposition()
            let videoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            
            // Create a video file with a colored frame
            var videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080
            ]
            
            #if os(iOS)
            videoSettings[AVVideoExpectedSourceFrameRateKey] = 30
            #endif
            
            let writer = try? AVAssetWriter(url: videoURL, fileType: .mp4)
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writer?.add(videoInput)
            
            // Create a colored frame
            let frameBuffer = createColoredFrame(size: CGSize(width: 1920, height: 1080), color: platformColor(.red))
            
            // Create a composition with the frame
            let frameComposition = AVMutableComposition()
            let frameTrack = frameComposition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
            
            // Insert the frame into the composition
            if let frameTrack = frameTrack {
                try? videoTrack?.insertTimeRange(
                    CMTimeRange(start: .zero, duration: CMTime(seconds: 5, preferredTimescale: 600)),
                    of: frameTrack,
                    at: .zero
                )
            }
            
            writer?.startWriting()
            writer?.finishWriting {}
        }
        
        return videoURL
    }
    
    private static func createColoredFrame(size: CGSize, color: CGColor) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attributes,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.setFillColor(color)
        context?.fill(CGRect(origin: .zero, size: size))
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }

    #if os(macOS)
    private static func platformColor(_ color: NSColor) -> CGColor {
        return color.cgColor
    }
    #else
    private static func platformColor(_ color: UIColor) -> CGColor {
        return color.cgColor
    }
    #endif
}
