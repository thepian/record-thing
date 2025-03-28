//
//  SimpleCameraView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 16.07.23.
//

import SwiftUI
import os

// https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameView.swift
public struct SimpleCameraView: View {
    let model: CameraViewModel
    var image: CGImage?
    private let label = Text("Live video frame")
    
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
                Image(image, scale: 1.0, orientation: .up, label: label)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
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
