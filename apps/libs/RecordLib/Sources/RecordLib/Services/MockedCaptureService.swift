//
//  MockedCaptureService.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 29.03.2025.
//

import AVFoundation
import CoreGraphics
import os

#if DEBUG
public class MockedCaptureService: CaptureService {
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "MockedCaptureService")
    private var status: AVAuthorizationStatus
    private var videoService: VideoFileStreamService?
    private var isStreaming: Bool = false
    
    public init(_ status: AVAuthorizationStatus) {
        self.status = status
        super.init()
    }
    
    public init(_ streamService: VideoFileStreamService, status: AVAuthorizationStatus = .authorized) {
        self.status = status
        self.videoService = streamService
        super.init()
    }
    
    override func checkPermission() -> AVAuthorizationStatus {
        permissionGranted = (status == .authorized)
        return status
    }
    
    override func startSessionIfAuthorized(completion: @escaping (Error?) -> ()) {
        guard status == .authorized else {
            completion(CaptureError.notAuthorized(comment: "Mock service denied permission"))
            return
        }
        
        // If we have a video service, start streaming frames
        if let videoService = videoService {
            isStreaming = true
            
            // Start the video service
            Task {
                do {
                    try await videoService.startStream()
                    
                    // Start streaming frames
                    while isStreaming {
                        if let frame = videoService.currentFrame {
                            // Update the parent class's frame variable on the main queue
                            await MainActor.run {
                                self.frame = frame
                            }
                        }
                        try await Task.sleep(nanoseconds: 1_000_000_000 / 30) // 30 FPS
                    }
                } catch {
                    logger.error("Failed to start video stream: \(error.localizedDescription)")
                    completion(error)
                }
            }
        }
        
        completion(nil)
    }
    
    override public func pauseStream() {
        guard !isPaused else {
            logger.debug("Mock stream already paused")
            return
        }
        
        isStreaming = false
        logger.debug("Mock camera stream paused")
        
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    override public func resumeStream() {
        guard isPaused else {
            logger.debug("Mock stream already running")
            return
        }
        
        // If we have a video service, restart streaming frames
        if let videoService = videoService {
            isStreaming = true
            
            // Start streaming frames
            Task {
                while isStreaming {
                    if let frame = videoService.currentFrame {
                        // Update the parent class's frame variable on the main queue
                        await MainActor.run {
                            self.frame = frame
                        }
                    }
                    try? await Task.sleep(nanoseconds: 1_000_000_000 / 30) // 30 FPS
                }
            }
        }
        
        logger.debug("Mock camera stream resumed")
        
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
}
#endif
