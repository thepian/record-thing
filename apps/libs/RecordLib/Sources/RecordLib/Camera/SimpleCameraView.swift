//
//  SimpleCameraView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 16.07.23.
//

import SwiftUI
import os

#if os(iOS)
import UIKit
#endif

// https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameView.swift
public struct SimpleCameraView: View {
    let model: CameraViewModel
    var image: CGImage?
    private let label = Text("Live video frame")
    
    #if os(iOS)
    @State private var currentOrientation: Image.Orientation = .up
    @State private var orientationUpdateTask: Task<Void, Never>?
    private let orientationDebounceInterval: TimeInterval = 0.2 // 200ms debounce
    #endif
    
    public init(model: CameraViewModel) {
        self.model = model
        self.image = nil
    }
    
    public init(model: CameraViewModel, image: CGImage?) {
        self.model = model
        self.image = image
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if let image = image {
                #if os(iOS)
                Image(image, scale: 1.0, orientation: currentOrientation, label: label)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .animation(.linear(duration: 0.2), value: currentOrientation)
                    .transition(.opacity.combined(with: .scale))
                    .onAppear {
                        updateOrientation()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                        updateOrientation()
                    }
                #else
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                #endif
            } else {
                Image(model.bgImageSet, bundle: Bundle.module)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    #if os(iOS)
    private func updateOrientation() {
        // Cancel any pending orientation update
        orientationUpdateTask?.cancel()
        
        // Create a new task with debounce
        orientationUpdateTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(orientationDebounceInterval * 1_000_000_000))
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            // Get the new orientation
            let newOrientation = calculateDeviceSpecificOrientation()
            
            // Update on main thread with animation
            await MainActor.run {
                withAnimation(.linear(duration: 0.2)) {
                    currentOrientation = newOrientation
                }
            }
        }
    }
    
    private func calculateDeviceSpecificOrientation() -> Image.Orientation {
        let device = UIDevice.current
        let orientation = device.orientation
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        // Get the interface orientation using the newer API
        let interfaceOrientation: UIInterfaceOrientation
        if #available(iOS 15.0, *) {
            interfaceOrientation = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows
                .first?
                .windowScene?
                .interfaceOrientation ?? .portrait
        } else {
            interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        }
        
        // For iPad, primarily use interface orientation
        if isIPad {
            switch interfaceOrientation {
            case .portraitUpsideDown:
                return .down
            case .landscapeLeft:
                return .left
            case .landscapeRight:
                return .right
            case .portrait, .unknown:
                return .up
            @unknown default:
                return .up
            }
        } else {
            // FIXME Transitions for rotation is messy
            // For iPhone, use device orientation but handle special cases
            switch orientation {
            case .portraitUpsideDown:
                return .down
            case .landscapeLeft:
                return .right // Flipped for iPhone camera
            case .landscapeRight:
                return .left // Flipped for iPhone camera
            case .faceUp, .faceDown:
                // When flat, use interface orientation
                switch interfaceOrientation {
                case .landscapeLeft:
                    return .right
                case .landscapeRight:
                    return .left
                case .portraitUpsideDown:
                    return .down
                case .portrait, .unknown:
                    return .up
                @unknown default:
                    return .up
                }
            case .portrait, .unknown:
                return .up
            @unknown default:
                return .up
            }
        }
    }
    #endif
}

#if DEBUG
struct SimpleCameraView_Previews: PreviewProvider {
    private static let logger = Logger(subsystem: "com.evidently.recordthing", category: "SimpleCameraView_Previews")
    
    static var previews: some View {
        @StateObject var model = CameraViewModel()
        
        // Create a preview with the default background image
        let defaultPreview = SimpleCameraView(model: model)
            .previewDisplayName("Default Background")
        
        // Create a preview with the mountain bike image
        let mountainBikeImage = loadCGImage(named: "thepia_a_high-end_electric_mountain_bike_1")
        let mountainBikePreview = SimpleCameraView(model: model, image: mountainBikeImage)
            .previewDisplayName("Mountain Bike")
        
        // Create a preview with video stream
        let videoPreview = VideoStreamPreview(model: model)
            .previewDisplayName("Video Stream")
        
        return Group {
            defaultPreview
            mountainBikePreview
            videoPreview
        }
    }
    
    // Helper function to load an image asset as CGImage
    static func loadCGImage(named imageName: String) -> CGImage? {
        // Load the RecordImage from the library bundle
        guard let recordImage = RecordImage.named(imageName) else {
            logger.error("Failed to load image named: \(imageName)")
            return nil
        }
        
        // Convert RecordImage to CGImage
        #if canImport(UIKit)
        return recordImage.cgImage
        #elseif canImport(AppKit)
        return recordImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }
}

// Preview view for video stream
struct VideoStreamPreview: View {
    private static let logger = Logger(subsystem: "com.evidently.recordthing", category: "VideoStreamPreview")
    
    @StateObject private var model: CameraViewModel
    @StateObject private var videoService: VideoFileStreamService
    @State private var isStreaming = false
    
    init(model: CameraViewModel) {
        self._model = StateObject(wrappedValue: model)
        // Create a video service with a sample video URL
        if let videoURL = Bundle.module.url(forResource: "sample_video", withExtension: "mp4") {
            self._videoService = StateObject(wrappedValue: VideoFileStreamService(videoURL: videoURL))
        } else {
            // Fallback to a temporary URL if the resource is not found
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("sample_video.mp4")
            self._videoService = StateObject(wrappedValue: VideoFileStreamService(videoURL: tempURL))
        }
    }
    
    var body: some View {
        SimpleCameraView(model: model, image: videoService.currentFrame)
            .task {
                do {
                    try await videoService.startStream()
                    isStreaming = true
                } catch {
                    VideoStreamPreview.logger.error("Failed to start video stream: \(error.localizedDescription)")
                }
            }
            .onDisappear {
                isStreaming = false
                videoService.stopStream()
            }
    }
}

// Helper for creating video previews
public struct VideoPreviewHelper {
    private static let logger = Logger(subsystem: "com.evidently.recordthing", category: "VideoPreviewHelper")
    
    public static func createVideoPreview() -> (VideoFileStreamService, MockedCaptureService)? {
        guard let videoURL = Bundle.module.url(forResource: "sample_video", withExtension: "mp4") else {
            logger.error("Failed to load sample_video.mp4 from module bundle")
            return nil
        }
        
        let videoService = VideoFileStreamService(videoURL: videoURL)
        let mockService = MockedCaptureService(videoService, status: .authorized)
        return (videoService, mockService)
    }
}
#endif
