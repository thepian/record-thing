import AVFoundation
import CoreGraphics
import CoreImage
import os

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Protocol defining the video stream interface
protocol VideoStreamService {
    var currentFrame: CGImage? { get }
    var isRunning: Bool { get }
    func startStream() async throws
    func stopStream()
}

/// Service that plays back a video file as a camera stream
public class VideoFileStreamService: VideoStreamService, ObservableObject {
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "VideoFileStreamService")
    
    @Published private(set) var currentFrame: CGImage?
    @Published private(set) var isRunning: Bool = false
    
    private var asset: AVAsset?
    private var assetReader: AVAssetReader?
    private var videoOutput: AVAssetReaderTrackOutput?
    private var lastFrameTime: CMTime = .zero
    private var frameRate: Double = 30.0
    private var cropToDevice: Bool = false
    private var videoDimensions: CMVideoDimensions?
    
    #if os(iOS)
    private var displayLink: CADisplayLink?
    private var deviceAspectRatio: CGFloat {
        let screen = UIScreen.main
        return screen.bounds.width / screen.bounds.height
    }
    #elseif os(macOS)
    private var displayLink: CVDisplayLink?
    private var deviceAspectRatio: CGFloat {
        guard let screen = NSScreen.main else { return 16.0/9.0 }
        return screen.frame.width / screen.frame.height
    }
    #endif
    
    public init(videoURL: URL, frameRate: Double = 30.0, cropToDevice: Bool = false) {
        self.asset = AVAsset(url: videoURL)
        self.frameRate = frameRate
        self.cropToDevice = cropToDevice
        
        // Setup asset reader in a task
        Task {
            await setupAssetReader()
        }
    }
    
    private func setupAssetReader() async {
        guard let asset = asset else { return }
        
        do {
            // Create asset reader
            assetReader = try AVAssetReader(asset: asset)
            
            // Get video track
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                logger.error("No video track found in asset")
                return
            }
            
            // Get video dimensions
            let dimensions = try await videoTrack.load(.naturalSize)
            videoDimensions = CMVideoDimensions(
                width: Int32(dimensions.width),
                height: Int32(dimensions.height)
            )
            
            // Configure output settings to maintain original dimensions
            let outputSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: videoDimensions?.width ?? 1920,
                kCVPixelBufferHeightKey as String: videoDimensions?.height ?? 1080
            ]
            
            // Create video output
            videoOutput = AVAssetReaderTrackOutput(
                track: videoTrack,
                outputSettings: outputSettings
            )
            
            if let videoOutput = videoOutput {
                assetReader?.add(videoOutput)
                logger.debug("Successfully setup video output with dimensions: \(self.videoDimensions?.width ?? 0)x\(self.videoDimensions?.height ?? 0)")
            }
        } catch {
            logger.error("Failed to setup asset reader: \(error.localizedDescription)")
        }
    }
    
    public func startStream() async throws {
        guard !isRunning, let assetReader = assetReader else { return }
        
        isRunning = true
        assetReader.startReading()
        
        await MainActor.run {
            #if os(iOS)
            // Setup display link for frame timing on iOS
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
            displayLink?.preferredFramesPerSecond = Int(frameRate)
            displayLink?.add(to: .main, forMode: .common)
            #elseif os(macOS)
            // Setup display link for frame timing on macOS
            var displayLink: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
            if let displayLink = displayLink {
                self.displayLink = displayLink
                CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, _, _, _, _, displayLinkContext) -> CVReturn in
                    let service = unsafeBitCast(displayLinkContext, to: VideoFileStreamService.self)
                    service.displayLinkDidFire()
                    return kCVReturnSuccess
                }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
                CVDisplayLinkStart(displayLink)
            }
            #endif
            logger.debug("Started video stream")
        }
    }
    
    public func stopStream() {
        isRunning = false
        assetReader?.cancelReading()
        
        #if os(iOS)
        displayLink?.invalidate()
        displayLink = nil
        #elseif os(macOS)
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }
        #endif
        
        lastFrameTime = .zero
        logger.debug("Stopped video stream")
    }
    
    @objc private func displayLinkDidFire() {
        guard let videoOutput = videoOutput,
              let sampleBuffer = videoOutput.copyNextSampleBuffer(),
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Convert pixel buffer to CGImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            if cropToDevice {
                currentFrame = cropImageToDeviceAspectRatio(cgImage)
            } else {
                currentFrame = cgImage
            }
        }
    }
    
    private func cropImageToDeviceAspectRatio(_ image: CGImage) -> CGImage? {
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let imageAspectRatio = imageWidth / imageHeight
        
        // Calculate crop rectangle
        var cropRect: CGRect
        
        if imageAspectRatio > deviceAspectRatio {
            // Image is wider than device, crop sides
            let newWidth = imageHeight * deviceAspectRatio
            let xOffset = (imageWidth - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageHeight)
        } else {
            // Image is taller than device, crop top and bottom
            let newHeight = imageWidth / deviceAspectRatio
            let yOffset = (imageHeight - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageWidth, height: newHeight)
        }
        
        // Convert to integer coordinates
        cropRect = cropRect.integral
        
        // Create cropped image
        return image.cropping(to: cropRect)
    }
} 
