//
//  ViewModel.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 09.07.23.
//

import Foundation
import AVFoundation
import Combine
import SwiftUICore
import os

struct Step {
    var iconName: String
    var text: String
    
    init(_ iconName: String, text: String) {
        self.iconName = iconName
        self.text = text
    }
}

let adviceSteps: [Step] = [
    Step("camera", text: "Treasure uses the camera to record your belongings."),
    Step("doc.viewfinder", text: "Show the full sales receipt in the view finder"),
    Step("camera", text: "Treasure uses the camera to record your belongings. Please Enable the Camera in the Settings"),
]

public struct Captured {
    /*
     Object conceptually related the capture
     */
    public var related: String
    // document
    // image
    // map3d
    // panorama
    
    public init(related: String) {
        self.related = related
    }
}

public enum OnboardingState {
    case PermitVideoCapture, CaptureInAppSettings, ShowAdvice, Done
}

// MARK: - Database Environment Key
public struct CameraViewModelKey: EnvironmentKey {
    public static let defaultValue: CameraViewModel? = nil
}

public extension EnvironmentValues {
    var cameraViewModel: CameraViewModel? {
        get { self[CameraViewModelKey.self] }
        set { self[CameraViewModelKey.self] = newValue }
    }
}

// MARK: Camera View Model

/*
 The Model is shared among views in the application.
 By passing it to ScanOrBelongingsView it becomes available to all descendants.
 */
public class CameraViewModel: ObservableObject {
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.camera-view-model")
    
    @Published public var showTopBar = true
    @Published public var title = "" // "Point at a Sales Receipt"
    @Published public var bgImageSet = "box_with_a_Swiss_watch_with_standing_on_a_coffee_table" // TODO change to branding asset. Copy with build script.
    @Published public var showViewfinderFrame = false
    
    @Published public var adviceIconName = "doc.viewfinder"
    @Published public var adviceText: String = "Show the full sales receipt in the view finder"
    
    @Published public var shaded: Bool = false

    @Published public var onboardingState = OnboardingState.PermitVideoCapture
    @Published public var showCamera = true
    @Published public var showAdvice = true
    @Published public var showBelongings = true
    
    @Published public var videoCaptureEnabled = false // If not, camera preview is hidden and explanation is shown
    @Published public var videoCaptureCTA = true // If so, show button for video capture permission
    
    // Add state management for CameraDrivenView
    @Published var isCameraActive: Bool = false
    @Published var cameraError: Error?
    @Published var isCameraPaused: Bool = false
    
    // Design system
    public let designSystem: DesignSystemSetup
    
    /*
     Photos, Topographical Maps, Clips, 3D scans captured by User Interactions
     are fed through this subject
     */
    public let captures = PassthroughSubject<Captured, Error>()
    
    // Reference to the capture service
    private(set) var captureService: CaptureService?
    
    public init(designSystem: DesignSystemSetup = .light) {
        self.designSystem = designSystem
    }
    
    public init(status: AVAuthorizationStatus, showViewfinderFrame: Bool = false, shaded: Bool = false, designSystem: DesignSystemSetup = .light) {
        self.designSystem = designSystem
        reflectCaptureDevice(status: status)
        self.showViewfinderFrame = showViewfinderFrame
        self.shaded = shaded
    }
    
    public func onAppear() {
        isCameraActive = true
//        print("TODO View Model on Appear")
    }
    
    public func onDisappear() {
        isCameraActive = false
    }
    
    public func onBackground() {
        isCameraActive = false
        pauseCamera()
        logger.debug("CameraViewModel entered background state")
    }
    
    public func onForeground() {
        isCameraActive = true
        resumeCamera()
        logger.debug("CameraViewModel entered foreground state")
    }
    
    /// Sets the capture service reference
    public func setCaptureService(_ service: CaptureService) {
        self.captureService = service
        logger.debug("Capture service set in CameraViewModel")
    }
    
    /// Pauses the camera stream
    public func pauseCamera() {
        guard let captureService = captureService else {
            logger.error("Cannot pause camera: capture service not set")
            return
        }
        
        captureService.pauseStream()
        isCameraPaused = true
        logger.debug("Camera paused")
    }
    
    /// Resumes the camera stream
    public func resumeCamera() {
        guard let captureService = captureService else {
            logger.error("Cannot resume camera: capture service not set")
            return
        }
        
        // Only resume if we're in the foreground and camera should be active
        guard isCameraActive else {
            logger.debug("Not resuming camera - not active")
            return
        }
        
        captureService.resumeStream()
        isCameraPaused = false
        logger.debug("Camera resumed")
    }
    
    public func reflectCaptureDevice(status: AVAuthorizationStatus) {
        switch status {
            case .authorized:
                self.onboardingState = OnboardingState.ShowAdvice
                self.showTopBar = true
                self.videoCaptureEnabled = true
                self.videoCaptureCTA = false
                self.showBelongings = true
                setAdvice(1)
            case .notDetermined:
                self.onboardingState = OnboardingState.PermitVideoCapture
                self.showTopBar = false
                self.videoCaptureEnabled = false
                self.videoCaptureCTA = true
                self.showBelongings = false
                setAdvice(0, showVideoAuthButton: true)
            default: // .denied .restricted
                self.onboardingState = OnboardingState.CaptureInAppSettings
                self.showTopBar = true
                self.videoCaptureEnabled = false
                self.videoCaptureCTA = false // or can it be done for .restricted?
                self.showBelongings = true
                setAdvice(1, showOpenSettingsButton: true)
        }
    }
    
    public func setAdvice(_ index: Int, showVideoAuthButton: Bool = false, showOpenSettingsButton: Bool = false) {
        self.adviceIconName = adviceSteps[index].iconName
        self.adviceText = adviceSteps[index].text
    }
    
    /*
    private func updateAppSnapshot() {
        // Get the current key window
        guard let window = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
                logger.error("Could not find key window for snapshot")
                return
            }
        
        // Create a snapshot of the current UI state
        if let snapshotView = window.snapshotView(afterScreenUpdates: true) {
            // Add the snapshot view to the window temporarily
            window.addSubview(snapshotView)
            
            // Remove it after a short delay (after the system has taken its snapshot)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                snapshotView.removeFromSuperview()
            }
            
            logger.debug("Updated app snapshot for task switcher")
        } else {
            logger.error("Failed to create snapshot view")
        }
    }
    */
}

// MARK: Mock CameraViewModel

#if DEBUG
extension CameraViewModel {
    static public var authorizedMock = {
        var viewModel = CameraViewModel(status: .authorized, shaded: false)
        viewModel.setCaptureService(MockedCaptureService(.authorized))
        return viewModel
    }
    
    static public var authorizedShadedMock = {
        var viewModel = CameraViewModel(status: .authorized, shaded: true)
        viewModel.setCaptureService(MockedCaptureService(.authorized))
        return viewModel
    }
    
    static public var deniedMock = {
        var viewModel = CameraViewModel(status: .denied, shaded: false)
        viewModel.setCaptureService(MockedCaptureService(.denied))
        return viewModel
    }
    
    static public var notDeterminedMock = {
        var viewModel = CameraViewModel(status: .notDetermined, shaded: false)
        viewModel.setCaptureService(MockedCaptureService(.notDetermined))
        return viewModel
    }

    static public var authorizedSampleVideoMock = {
        var viewModel = CameraViewModel(status: .authorized, shaded: false)
        if let videoURL = Bundle.module.url(forResource: "sample_video", withExtension: "mp4") {
            let videoService = VideoFileStreamService(videoURL: videoURL)
            let mockService = MockedCaptureService(videoService, status: .authorized)
            
            viewModel.setCaptureService(mockService)
        }
        return viewModel
    }
}
#endif
