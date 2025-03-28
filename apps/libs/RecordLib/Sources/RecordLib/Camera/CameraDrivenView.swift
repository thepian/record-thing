//
//  CameraDrivenView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 18.07.23.
//

import SwiftUI
import SwiftUICore
import os

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct CameraDrivenView<CameraOverlayView: View>: View {
    @Environment(\.cameraViewModel) var cameraViewModel: CameraViewModel?
    @StateObject var captureService: CaptureService
    @State var bgImage: RecordImage?
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.camera-driven-view")
    
    var cameraOverlayView: CameraOverlayView
    
    // Get screen dimensions in a cross-platform way
    #if os(macOS)
    private var screenWidth: CGFloat {
        if let designSystem = cameraViewModel?.designSystem {
            return min(max(designSystem.windowDefaultWidth, designSystem.windowMinWidth), designSystem.windowMaxWidth)
        }
        return 1280
    }
    private var screenHeight: CGFloat {
        if let designSystem = cameraViewModel?.designSystem {
            return min(max(designSystem.windowDefaultHeight, designSystem.windowMinHeight), designSystem.windowMaxHeight)
        }
        return 720
    }
    #else
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    #endif
    
    // Add public initializer
    public init(captureService: CaptureService,
        @ViewBuilder cameraOverlayView: () -> CameraOverlayView) {
        self._captureService = StateObject(wrappedValue: captureService)
        self.cameraOverlayView = cameraOverlayView()
        logger.trace("CameraDrivenView initialized")
    }
    
    func takeSnap() {
        captureService.capturePhoto()
        cameraViewModel?.captures.send(Captured(related: "belonging-5"))
        logger.debug("Photo capture requested")
    }
    
    func startRecording() {
        // captureService.startRecording()
        logger.debug("Recording start requested (not implemented)")
    }
    
    func endRecording() {
        // captureService.endRecording()
        cameraViewModel?.captures.send(Captured(related: "belonging-51"))
        logger.debug("Recording end requested (not implemented)")
    }
    
    // Helper function to handle permission changes
    private func handlePermissionChange(oldValue: Bool, newValue: Bool) {
        logger.debug("Permission changed from \(oldValue) to \(newValue)")
        if newValue {
            // Permission was just granted, start the session
            captureService.startSessionIfAuthorized(completion: { err in
                if let error = err {
                    logger.error("Session not started after permission change: \(error.localizedDescription)")
                } else {
                    logger.debug("Camera session started successfully after permission change")
                }
            })
            
            // Update the camera view model
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            cameraViewModel?.reflectCaptureDevice(status: status)
        } else if oldValue {
            // Permission was just revoked, update the camera view model
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            cameraViewModel?.reflectCaptureDevice(status: status)
        }
    }

    public var body: some View {
        ZStack {
            if let cameraViewModel = cameraViewModel {
                SimpleCameraView(model: cameraViewModel, image: captureService.frame)

                // Semi-transparent background
                if cameraViewModel.shaded {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            

            if !captureService.permissionGranted {
                VStack {
                    Spacer()
                    PermitRequiredView(
                        permitAlert: captureService.askForPermission,
                        showSettings: captureService.openAppSettings
                    )
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 32, trailing: 16))
                .onAppear {
                    logger.debug("Camera permission not granted, showing permission request view")
                }
            } else {
                cameraOverlayView
                    .frame(width: screenWidth, height: screenHeight)
                    .onAppear {
                        logger.debug("Camera permission granted, showing camera overlay view")
                    }
            }
        }
        #if os(macOS)
        .frame(minWidth: cameraViewModel?.designSystem.windowMinWidth ?? 800,
               maxWidth: cameraViewModel?.designSystem.windowMaxWidth ?? 1920,
               minHeight: cameraViewModel?.designSystem.windowMinHeight ?? 600,
               maxHeight: cameraViewModel?.designSystem.windowMaxHeight ?? 1080)
        #else
        .frame(width: screenWidth, height: screenHeight)
        #endif
        // From iOS 15: https://www.hackingwithswift.com/quick-start/swiftui/how-to-run-an-asynchronous-task-when-a-view-is-shown
        .task {
            logger.debug("CameraDrivenView task started")
            let status = captureService.checkPermission()
            cameraViewModel?.reflectCaptureDevice(status: status)
            cameraViewModel?.setCaptureService(captureService)
            captureService.startSessionIfAuthorized(completion: { err in
                if let error = err {
                    logger.error("Session not started: \(error.localizedDescription)")
                } else {
                    logger.debug("Camera session started successfully")
                }
            })
        }
        #if os(macOS)
        .onChange(of: captureService.permissionGranted, initial: false) { _, newValue in
            handlePermissionChange(oldValue: !newValue, newValue: newValue)
        }
        .onChange(of: cameraViewModel?.isCameraPaused ?? false, initial: false) { _, isPaused in
            if isPaused {
                captureService.pauseStream()
                logger.debug("Camera stream paused from view model")
            } else {
                captureService.resumeStream()
                logger.debug("Camera stream resumed from view model")
            }
        }
        #else
        .onChange(of: captureService.permissionGranted) { newValue in
            handlePermissionChange(oldValue: !newValue, newValue: newValue)
        }
        .onChange(of: cameraViewModel?.isCameraPaused ?? false) { isPaused in
            if isPaused {
                captureService.pauseStream()
                logger.debug("Camera stream paused from view model")
            } else {
                captureService.resumeStream()
                logger.debug("Camera stream resumed from view model")
            }
        }
        #endif
    }
}

#if DEBUG
import AVFoundation

enum ExampleDest: Hashable {
    case evidence
}

struct CameraDrivenView_Previews: PreviewProvider {
    private static let logger = Logger(subsystem: "com.evidently.recordthing", category: "CameraDrivenView_Previews")
    
    static var previews: some View {
        @StateObject var viewModel = MockedRecordedThingViewModel.create(evidenceOptions: [])
        
        Group {
            
            NavigationStack {
                CameraDrivenView(captureService: MockedCaptureService(.authorized)) {
                    VStack {
                        Spacer()
                        NavigationLink("Evidence", value: ExampleDest.evidence)
                        //                    ReservedForCameraView()
                        RecordedStackAndRequirementsView(viewModel: viewModel)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 32))
                        StandardFloatingToolbar(
                            useFullRounding: false,
                            onDataBrowseTapped: {
                            },
                            onStackTapped: {
                            },
                            onCameraTapped: {
                            },
                            onAccountTapped: {
                            }
                        )
                        .frame(height: 100)
                        ClarifyEvidenceControl(viewModel: viewModel)
                    }
                }
                .environment(\.cameraViewModel, CameraViewModel.authorizedMock())
                .previewDisplayName("Record Advice")
                .navigationDestination(for: ExampleDest.self) { dest in
                    switch dest {
                    case .evidence:
                        CameraDrivenView(captureService: MockedCaptureService(.authorized)) {
                            VStack {
                                Spacer()
                                RecordedStackAndRequirementsView(viewModel: viewModel)
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 32))
                                StandardFloatingToolbar(                            useFullRounding: false,
                                    onDataBrowseTapped: { },
                                    onStackTapped: { },
                                    onCameraTapped: { },
                                    onAccountTapped: { })
                                    .frame(height: 100)
                                ClarifyEvidenceControl(viewModel: viewModel)
                            }
                        }
                        .environment(\.cameraViewModel, CameraViewModel.authorizedMock())
                        .navigationTitle("Evidence")
//                            }
//                        }
                    }
                }
            }
            
            CameraDrivenView(captureService: MockedCaptureService(.authorized)) {
                VStack {
                    Spacer()
                    //                    ReservedForCameraView()
                    RecordedStackAndRequirementsView(viewModel: viewModel)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 32))
                    StandardFloatingToolbar(
                        useFullRounding: false,
                        onDataBrowseTapped: {
                        },
                        onStackTapped: {
                        },
                        onCameraTapped: {
                        },
                        onAccountTapped: {
                        }
                    )
                    .frame(height: 100)
                    ClarifyEvidenceControl(viewModel: viewModel)
                }
//                if let designSystem = cameraViewModel?.designSystem {
                    EvidenceReview(viewModel: viewModel)
                    .offset(x: 80, y: 60)
                    .frame(width: 1080, height: 1480)
//                        .frame(width: designSystem.screenWidth, height: designSystem.height * 0.8)
//                }
            }
            .environment(\.cameraViewModel, CameraViewModel.authorizedShadedMock())
            .previewDisplayName("Record Review")
            
            // Create preview with authorized camera
            CameraDrivenView(captureService: MockedCaptureService(.authorized)) {
                VStack {
                    Spacer()
                    ReservedForCameraView()
                    CheckboxCarouselView(
                        viewModel: viewModel
                    )
                    .padding()
                    .cornerRadius(12)
                }
            }
            .environment(\.cameraViewModel, CameraViewModel.authorizedMock())
            .previewDisplayName("Authorized")

            // Create preview with undefined camera permissions
            CameraDrivenView(captureService: MockedCaptureService(.notDetermined)) {
                EmptyView()
            }
            .environment(\.cameraViewModel, CameraViewModel.notDeterminedMock())
            .previewDisplayName("Missing Permissions")

            // Create preview with denied camera permissions
            CameraDrivenView(captureService: MockedCaptureService(.denied)) {
                EmptyView()
            }
            .environment(\.cameraViewModel, CameraViewModel.deniedMock())
            .previewDisplayName("Denied Capture")
        }
        
        Group {
            // Video File Service Preview
            if let videoURL = Bundle.module.url(forResource: "sample_video", withExtension: "mp4") {
                let videoService = VideoFileStreamService(videoURL: videoURL)
                let mockService = MockedCaptureService(videoService, status: .authorized)
                
                CameraDrivenView(captureService: mockService) {
                    VStack {
                        Spacer()
                        ReservedForCameraView()
                        CheckboxCarouselView(
                            viewModel: viewModel
                        )
                        .padding()
                        .cornerRadius(12)
                    }
                }
                .environment(\.cameraViewModel, CameraViewModel(status: .authorized))
                .previewDisplayName("Video File Service")
            }
            
            // Camera Service Preview (if available)
//            if let cameraService = try? CameraService() {
//                CameraDrivenView(
//                    viewModel: RecordedThingViewModel(
//                        captureService: cameraService,
//                        onOptionConfirmed: { _, _ in }
//                    )
//                )
//                .previewDisplayName("Camera Service")
//            }
        }
    }
}
#endif
