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
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.camera-driven-view")
    
    var cameraOverlayView: CameraOverlayView
    
    // Get screen dimensions in a cross-platform way
    #if os(macOS)
    private var screenWidth: CGFloat {
        NSScreen.main?.frame.width ?? 800
    }
    private var screenHeight: CGFloat {
        NSScreen.main?.frame.height ?? 600
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
        logger.debug("CameraDrivenView initialized")
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
                .frame(maxWidth: screenWidth, maxHeight: screenHeight)
                .onAppear {
                    logger.debug("Camera permission granted, showing camera overlay view")
                }
            }
        }
        // From iOS 15: https://www.hackingwithswift.com/quick-start/swiftui/how-to-run-an-asynchronous-task-when-a-view-is-shown
        .task {
            logger.debug("CameraDrivenView task started")
            let status = captureService.checkPermission()
            cameraViewModel?.reflectCaptureDevice(status: status)
            captureService.startSessionIfAuthorized(completion: { err in
                if let error = err {
                    logger.error("Session not started: \(error.localizedDescription)")
                } else {
                    logger.debug("Camera session started successfully")
                }
            })
        }
        // Use the appropriate onChange modifier based on iOS version
//        #if swift(>=5.9) // iOS 17 and later
//        .onChange(of: captureService.permissionGranted) { oldValue, newValue in
//            handlePermissionChange(oldValue: oldValue, newValue: newValue)
//        }
//        #else // iOS 16 and earlier
        .onChange(of: captureService.permissionGranted) { newValue in
            // For iOS 16, we don't have access to the old value directly
            // We can infer it was the opposite of the new value if it changed
            let oldValue = !newValue // This is an approximation
            handlePermissionChange(oldValue: oldValue, newValue: newValue)
        }
//        #endif
    }
}

#if DEBUG
import AVFoundation

struct CameraDrivenView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var viewModel = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take a photo of the product"),
                CheckboxItem(text: "Scan the barcode"),
                CheckboxItem(text: "Capture the receipt")
            ],
            cardImages: [
                .system("moon.fill"),
                .system("star.fill")
            ]
//            checkboxTextColor: .white,
//            checkboxColor: .white
        )
        
        Group {
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
            .environment(\.cameraViewModel, CameraViewModel(.authorized))
            .previewDisplayName("Authorized")

            // Create preview with undefined camera permissions
            CameraDrivenView(captureService: MockedCaptureService(.notDetermined)) {
                EmptyView()
            }
            .environment(\.cameraViewModel, CameraViewModel(.notDetermined))
            .previewDisplayName("Missing Permissions")

            // Create preview with denied camera permissions
            CameraDrivenView(captureService: MockedCaptureService(.denied)) {
                EmptyView()
            }
            .environment(\.cameraViewModel, CameraViewModel(.denied))
            .previewDisplayName("Denied Capture")
        }
    }
}
#endif
