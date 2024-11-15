//
//  VisionService+Session.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 14.11.2023.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision

extension VisionService {
    
    public func onScenePhase(_ phase: ScenePhase) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch(phase) {
        case .active: // On application startup or resume
            if autoRunSession && status == .authorized {
                // If autoRun & permissioned
                configureSession()
                activateSession("Scene Active")
            }
            break
        case .inactive:
            if autoRunSession {
                inactivateSession()
            }
            break
        default:
            break
        }
    }
    
    func configureSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if !sessionConfigured && status == .authorized {
            if session.isRunning {
                session.stopRunning()
                session = AVCaptureSession()
            }
            setupVideoCaptureSession() // Camera Input capture
            
            setSessionOutputsAsync(metadata: appCodeDetection || faceDetection || otherCodeDetection, photo: false, video: false)
            sessionConfigured = true
        }
    }
    
    func activateSession(_ cause: String) {
            nextDetectTime = Date.now
            nextRenderTime = Date.now
            self.sessionQueue.async { [unowned self] in
                if !self.session.isRunning {
                    self.prepareVision() // full detection/trackers
                    self.session.startRunning()
                    print("Started capture session, triggered by \(cause)")
                }
            }
    }
    
    // TODO refresh the session every 5 minutes to clear memory leaks. Or if no new movement or detections for a while.

    func inactivateSession() {
            // TODO silence publishing with isCameraActive
//            model?.mainDocument = nil
            session.stopRunning()
            forgetVision()
    }
    
    private func setupPhotoCaptureSession() {
        // Configure the photo output's behavior.
//TODO        photoOutput.isHighResolutionCaptureEnabled = true
        
        // No Live Photo as MovieFile is needed from the session
        //        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
    }
    
    private func setSessionOutputsAsync(metadata: Bool, photo: Bool, video: Bool) {
        sessionQueue.async { [unowned self] in
            // TODO does session.isRunning have to be true

            if metadata && !metadataOutputEnabled {
                setupMetaDetectionSession()
                metadataOutputEnabled = true
            }
            if !metadata && metadataOutputEnabled {
                session.removeOutput(metadataOutput)
                metadataOutputEnabled = false
            }
            if photo && !photoOutputEnabled {
                setupPhotoCaptureSession()
                // TODO photo
                photoOutputEnabled = true
            }
            if video && !videoOutputEnabled {
                setupVideoRecordingSession()
                // TODO video
                videoOutputEnabled = true
            }
        }
    }

    public func applyCamera(faceDetection: Bool?, documentDetection: Bool?, iOSDocumentDetection: Bool?, appCodeDetection: Bool?, reality: Bool?) {
        
        self.faceDetection = faceDetection ?? self.faceDetection
        self.documentDetection = documentDetection ?? self.documentDetection
        self.iOSDocumentDetection = iOSDocumentDetection ?? self.iOSDocumentDetection
        self.appCodeDetection = appCodeDetection ?? self.appCodeDetection
        self.reality = reality ?? self.reality
        
        // TODO start appropriate session
        // TODO update VisionModel to change what is shown
        
//        cameraView: CameraViewType Standard
        
        if self.reality {
            // Choose AR Camera
            if model?.cameraView != .AR {
                // stop the plain session
                session.stopRunning()
                // TODO start AR session
                model?.cameraView = .AR
            }
        } else if self.iOSDocumentDetection {
            // Choose iOSDocument
            if model?.cameraView != .iOSDocument {
                // stop the plain session
                // TODO start document session
                session.stopRunning()
                model?.cameraView = .iOSDocument
            }
        } else {
            // Choose Regular Camera
            if model?.cameraView != .Standard {
                // start the plain session
                activateSession("switching camera type from \(String(describing: model?.cameraView))")
            }
        }
    }

}
