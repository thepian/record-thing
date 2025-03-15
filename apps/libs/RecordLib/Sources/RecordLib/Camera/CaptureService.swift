//
//  CaptureService.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 15.07.23.
//

import Foundation
import AVFoundation
import CoreImage
import os

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum CaptureError: Error {
    case notAuthorized(comment: String)
    case deviceNotAvailable(comment: String)
    // Throw in all other cases
    case unexpected(code: Int)
}

public class CaptureService: NSObject, ObservableObject {
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "capture-service")
    
    @Published var frame: CGImage? // For streaming to view via CoreImage
    private let session = AVCaptureSession()  // Should be possible to reuse the capture session
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()

    var delegate: AVCapturePhotoCaptureDelegate?
    
    @Published var permissionGranted = false
    // Track previous permission state to help with iOS 16 compatibility
    private var previousPermissionState = false
    
    // Timer for permission monitoring
    private var permissionCheckTimer: Timer?
    
    let photoOutput = AVCapturePhotoOutput() // For capturing photos
    
    public override init() {
        super.init()
        logger.debug("CaptureService initialized")
        
        // Initial permission check
        let initialStatus = AVCaptureDevice.authorizationStatus(for: .video)
        permissionGranted = initialStatus == .authorized
        previousPermissionState = permissionGranted
        
        // Setup notification observers for app state changes
        setupNotificationObservers()
    }
    
    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Invalidate timer
        permissionCheckTimer?.invalidate()
    }
    
    private func setupNotificationObservers() {
        // Register for app becoming active notification
        #if os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #else
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // For iOS, also observe settings bundle changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
        
        logger.debug("Notification observers set up for permission monitoring")
    }
    
    @objc private func applicationDidBecomeActive() {
        logger.debug("Application became active, checking camera permissions")
        checkAndUpdatePermissions()
    }
    
    private func checkAndUpdatePermissions() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let wasGranted = permissionGranted
        previousPermissionState = permissionGranted
        permissionGranted = currentStatus == .authorized
        
        logger.debug("Permission check: current=\(currentStatus.rawValue), permissionGranted=\(self.permissionGranted), previousState=\(self.previousPermissionState)")
        
        // If permission status changed, update the session
        if wasGranted != permissionGranted {
            logger.debug("Permission status changed from \(wasGranted) to \(self.permissionGranted)")
            
            // If permission was just granted, start the session
            if permissionGranted {
                logger.debug("Permission newly granted, starting session")
                startSessionIfAuthorized { error in
                    if let error = error {
                        self.logger.error("Failed to start session after permission change: \(error.localizedDescription)")
                    } else {
                        self.logger.debug("Session started successfully after permission change")
                    }
                }
            } else if wasGranted {
                // If permission was revoked, stop the session
                logger.debug("Permission revoked, stopping session")
                sessionQueue.async {
                    if self.session.isRunning {
                        self.session.stopRunning()
                    }
                }
            }
        }
    }
    
    // Start periodic permission checking
    private func startPermissionMonitoring() {
        // Stop any existing timer
        permissionCheckTimer?.invalidate()
        
        // Create a new timer that checks permissions every 2 seconds
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkAndUpdatePermissions()
        }
        
        logger.debug("Started permission monitoring timer")
    }
    
    // Stop periodic permission checking
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
        logger.debug("Stopped permission monitoring timer")
    }
    
    // Get the previous permission state (useful for iOS 16 compatibility)
    public func getPreviousPermissionState() -> Bool {
        return previousPermissionState
    }
    
    public func start(_ requirePermissionsIfNeeded: Bool, delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        start(requirePermissionsIfNeeded, completion: completion)
    }
    
    public func start(_ requirePermissionsIfNeeded: Bool, completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined, .denied:
            if requirePermissionsIfNeeded {
                askForPermissionIfNeeded() { err in
                    if err == nil {
                        self.sessionQueue.async { [unowned self] in
                            setupCaptureSession(completion: completion)
                            if !session.isRunning {
                                session.startRunning()
                                logger.debug("Started running")
                            }
                        }
                    }
                }
                
                // Start monitoring for permission changes
                startPermissionMonitoring()
            }
            break
        case .restricted, .authorized:
            permissionGranted = true
            previousPermissionState = true
            sessionQueue.async { [unowned self] in
                setupCaptureSession(completion: completion)
                if !session.isRunning {
                    session.startRunning()
                    logger.debug("Started running (start)")
                }
            }
        @unknown default:
            break
        }
    }
    
    func checkPermission() -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        previousPermissionState = permissionGranted
        switch status {
        case .restricted, .authorized: // The user has previously granted access to the camera.
            permissionGranted = true
                                
        // Combine the two other cases into the default case
        default:
            permissionGranted = false
        }
        return status
    }
    
    func startSessionIfAuthorized(completion: @escaping (Error?) -> ()) {
        if permissionGranted {
            sessionQueue.async { [unowned self] in
                self.setupCaptureSession(completion: completion)
                self.session.startRunning()
                logger.debug("Started session running. (startSessionIfAuthorized)")
                completion(nil)
            }
        } else {
            completion(CaptureError.notAuthorized(comment: "Not starting session due to missing permission"))
            logger.error("Not starting session due to missing permission")
            
            // Start monitoring for permission changes
            startPermissionMonitoring()
        }
    }
    
    func setupCaptureSession(completion: @escaping (Error?) -> ()) {
        // Find appropriate camera device based on platform
        var videoDevice: AVCaptureDevice?
        
        #if os(macOS)
        // On macOS, get the default video device
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        videoDevice = discoverySession.devices.first
        logger.debug("macOS camera setup: found \(discoverySession.devices.count) devices")
        #else
        // On iOS, try to get the back dual camera, or fall back to any video device
        videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) ?? 
                     AVCaptureDevice.default(for: .video)
        #endif
        
        guard let videoDevice = videoDevice else {
            logger.error("No camera device found")
            completion(CaptureError.deviceNotAvailable(comment: "No camera device found"))
            return
        }
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            logger.error("Could not create video device input")
            completion(CaptureError.deviceNotAvailable(comment: "Could not create video device input"))
            return
        }

        // Configure the session
        session.beginConfiguration()
        
        // Remove any existing inputs and outputs
        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        // Add the video input
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            logger.debug("Added video input to session")
        } else {
            logger.error("Could not add video input to session")
            completion(CaptureError.unexpected(code: 1001))
            return
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            logger.debug("Added photo output to session")
        } else {
            logger.error("Could not add photo output to session")
        }
        
        // Add video output for frame preview
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            logger.debug("Added video output to session")
            
            // Set video orientation if connection exists
            if let connection = videoOutput.connection(with: .video) {
                #if os(iOS)
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                #endif
            }
        } else {
            logger.error("Could not add video output to session")
        }
        
        session.commitConfiguration()
        logger.debug("Capture session setup completed")
        completion(nil)
    }
    
    public func openAppSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                logger.debug("Opening app settings")
                
                // Start monitoring for permission changes
                startPermissionMonitoring()
            }
        }
        #elseif os(macOS)
        // On macOS, open System Preferences > Security & Privacy > Privacy > Camera
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
            logger.debug("Opening macOS camera privacy settings")
            
            // Start monitoring for permission changes
            startPermissionMonitoring()
        }
        #endif
    }
    
    public func askForPermissionIfNeeded(completion: @escaping (Error?) -> ()) {
        if !permissionGranted {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .restricted, .authorized:
                permissionGranted = true
                logger.debug("Camera access already authorized")
                completion(nil)
                
            case .denied:
                logger.debug("Camera access denied, opening settings")
                openAppSettings()
                // Start monitoring for permission changes
                startPermissionMonitoring()

            case .notDetermined:
                // Strong reference not a problem here but might become one in the future.
                logger.debug("Requesting camera access")
                AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                    self.permissionGranted = granted
                    logger.debug("Camera access \(granted ? "granted" : "denied")")
                    completion(nil)
                    
                    // Start monitoring for permission changes if denied
                    if !granted {
                        self.startPermissionMonitoring()
                    }
                }
            default:
                break;
            }
        } else {
            completion(nil)
        }
    }
    
    // called from view button
    public func askForPermission() async {
        logger.debug("Requesting camera access asynchronously")
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        
        // Update permission state
        DispatchQueue.main.async {
            self.permissionGranted = granted
            self.logger.debug("Camera access \(granted ? "granted" : "denied") asynchronously")
            
            // Start monitoring for permission changes if denied
            if !granted {
                self.startPermissionMonitoring()
            }
        }
        
        // TODO fix this leaks the continuation
        await withCheckedContinuation { continuation in
            self.startSessionIfAuthorized() { err in
                if let error = err {
                    self.logger.error("Failed to start session: \(error.localizedDescription)")
                } else {
                    self.logger.debug("Session started after permission granted")
                }
                continuation.resume()
            }
        }
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        if delegate != nil {
            photoOutput.capturePhoto(with: settings, delegate: delegate!)
            logger.debug("Captured photo with delegate")
            return
        }
            
        sessionQueue.async {
            // Handle the deprecated isHighResolutionPhotoEnabled property
            if #available(iOS 16.0, macOS 13.0, *) {
                // Use maxPhotoDimensions for iOS 16.0/macOS 13.0 and later
                // Set to a reasonable default resolution (e.g., 4K)
                let dimensions = CMVideoDimensions(width: 3840, height: 2160)
                settings.maxPhotoDimensions = dimensions
                self.logger.debug("Using maxPhotoDimensions for photo capture")
            } else {
                // Use isHighResolutionPhotoEnabled for earlier versions
                settings.isHighResolutionPhotoEnabled = false
                self.logger.debug("Using isHighResolutionPhotoEnabled for photo capture")
            }
            
            let photoCaptureProcessor = PhotoCaptureProcessorRef(with: settings, willCapturePhotoAnimation: {
                // Flash the screen to signal that a photo was taken
                DispatchQueue.main.async {
                    self.logger.debug("Photo capture animation")
                }
            }, livePhotoCaptureHandler: { capturing in
                self.logger.debug("Live photo capture: \(capturing ? "started" : "ended")")
            }, completionHandler: { photoCaptureProcessor in
                self.logger.debug("Photo capture completed")
            }, photoProcessingHandler: { animate in
                DispatchQueue.main.async {
                    self.logger.debug("Photo processing: \(animate ? "started" : "completed")")
                }
            })
            
            #if os(iOS)
            self.photoOutput.capturePhoto(with: settings, delegate: photoCaptureProcessor)
            #endif
            self.logger.debug("Photo capture initiated")
        }
    }
}

// Core Image sample buffer streaming
extension CaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
                
        // All UI updates should be/ must be performed on the main queue.
        DispatchQueue.main.async { [unowned self] in
            self.frame = cgImage
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return cgImage
    }
}

public class MockedCaptureService: CaptureService {
    var status: AVAuthorizationStatus
    
    public init(_ status: AVAuthorizationStatus) {
        self.status = status
        super.init()
    }
    
    override func checkPermission() -> AVAuthorizationStatus {
        permissionGranted = (status == .authorized)
        return status
    }
    
    override func startSessionIfAuthorized(completion: @escaping (Error?) -> ()) {
        // Mock implementation - just call completion
        completion(status == .authorized ? nil : CaptureError.notAuthorized(comment: "Mock service denied permission"))
    }
}

