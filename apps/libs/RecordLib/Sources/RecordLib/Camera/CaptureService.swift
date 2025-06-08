//
//  CaptureService.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 15.07.23.
//

import AVFoundation
import CoreImage
import CoreMotion
import Foundation
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

/*
  Capture sessions are limited to 30 minutes to get rid of memory leaks. When the session reaches 30 minutes,
  it will be restarted. Pausing will reset the timer.
*/
public class CaptureService: NSObject, ObservableObject {
  let leaveMostRecentFrameOnSleep: Bool = true

  // Logger for debugging
  let logger = Logger(subsystem: "com.record-thing", category: "capture-service")

  @Published public var frame: CGImage?  // For streaming to view via CoreImage
  public let session = AVCaptureSession()  // Should be possible to reuse the capture session
  let sessionQueue = DispatchQueue(label: "sessionQueue")
  private let context = CIContext()

  var delegate: AVCapturePhotoCaptureDelegate?

  @Published var permissionGranted = false
  // Track previous permission state to help with iOS 16 compatibility
  private var previousPermissionState = false

  // Timer for permission monitoring
  private var permissionCheckTimer: Timer?

  // Track if the session is paused
  @Published public var isPaused = false

  let photoOutput = AVCapturePhotoOutput()  // For capturing photos

  // Motion detection properties
  #if os(iOS)
    let motionManager = CMMotionManager()
  #else
    var mouseMonitor: Any?
    var lastMouseMoveTime: Date = Date()
  #endif
  var lastMotionTime: Date = Date()
  var motionTimer: Timer?
  let motionTimeout: TimeInterval = 30.0  // 30 seconds of no motion before pausing
  let accelerometerUpdateInterval: TimeInterval = 0.1  // 10 Hz
  let motionThreshold: Double = 1.01  // Threshold for significant motion

  @Published public var isSubdued: Bool = false {
    didSet {
      if oldValue != isSubdued {
        updateSessionConfiguration()
      }
    }
  }

  // Session duration monitoring
  var sessionStartTime: Date?
  var sessionDurationTimer: Timer?
  let defaultSessionDuration: TimeInterval = 30 * 60  // 30 minutes in seconds

  // Add orientation tracking
  #if os(iOS)
    var currentOrientation: UIDeviceOrientation = .portrait
    private var orientationObserver: NSObjectProtocol?
  #endif

  public override init() {
    super.init()
    logger.debug("CaptureService initialized")

    // Initial permission check
    let initialStatus = AVCaptureDevice.authorizationStatus(for: .video)
    permissionGranted = initialStatus == .authorized
    previousPermissionState = permissionGranted

    // Setup notification observers for app state changes
    setupNotificationObservers()

    // Setup motion detection
    setupMotionDetection()

    #if os(iOS)
      // Setup orientation tracking
      setupOrientationTracking()
    #endif
  }

  deinit {
    // Remove notification observers
    NotificationCenter.default.removeObserver(self)

    #if os(iOS)
      // Remove orientation observer
      if let observer = orientationObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    #endif

    // Invalidate timers
    permissionCheckTimer?.invalidate()
    motionTimer?.invalidate()

    #if os(iOS)
      // Stop motion updates
      motionManager.stopAccelerometerUpdates()
    #else
      // Remove mouse monitor
      if let monitor = mouseMonitor {
        NSEvent.removeMonitor(monitor)
      }
    #endif

    // Clean up capture resources directly
    if session.isRunning {
      session.stopRunning()
    }

    // Remove all inputs and outputs
    session.beginConfiguration()

    // Remove all inputs
    for input in session.inputs {
      session.removeInput(input)
    }

    // Remove all outputs
    for output in session.outputs {
      session.removeOutput(output)
    }

    session.commitConfiguration()

    // Clear the current frame
    frame = nil

    logger.debug("CaptureService deinitialized")
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
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationWillResignActive),
        name: NSApplication.willResignActiveNotification,
        object: nil
      )
    #else
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationDidBecomeActive),
        name: UIApplication.didBecomeActiveNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationWillResignActive),
        name: UIApplication.willResignActiveNotification,
        object: nil
      )

    // Doesn't seem to exist
    //        NotificationCenter.default.addObserver(
    //            self,
    //            selector: #selector(applicationWillTerminate),
    //            name: UIApplication.willResignActiveNotification,
    //            object: nil
    //        )
    #endif

    // Add memory pressure observer
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMemoryPressure),
      name: .memoryPressureHigh,
      object: nil
    )

    logger.debug("Notification observers set up for permission monitoring and memory pressure")
  }

  @objc private func applicationWillResignActive() {
    logger.debug("Application will resign active, cleaning up capture resources")

    cleanupCaptureResources()
  }

  @objc private func applicationDidBecomeActive() {
    logger.debug("Application became active, restoring capture session")

    sessionQueue.async { [weak self] in
      guard let self = self else { return }

      // Only proceed if we have permission
      guard self.permissionGranted else {
        self.logger.debug("Not restoring session - no camera permission")
        return
      }

      // Reconfigure the session with fresh inputs and outputs
      self.setupCaptureSession { [weak self] error in
        guard let self = self else { return }

        if let error = error {
          self.logger.error("Failed to reconfigure session: \(error.localizedDescription)")
          return
        }

        // Start the session if it's not already running
        if !self.session.isRunning {
          self.session.startRunning()
          self.logger.debug("Capture session restored and running")

          // Update the paused state on the main thread
          DispatchQueue.main.async {
            self.isPaused = false
          }
        } else {
          self.logger.debug("Capture session already running")
        }
      }
    }
  }

  @objc private func handleMemoryPressure(_ notification: Notification) {
    logger.warning("Received memory pressure notification - pausing camera stream")

    // Pause the camera stream to reduce memory usage
    pauseStream()

    // If memory pressure is critical, also reduce session quality
    if let userInfo = notification.userInfo,
      let level = userInfo["level"] as? MemoryMonitor.MemoryPressureLevel,
      level == .emergency
    {
      logger.warning("Emergency memory pressure - reducing camera quality")

      sessionQueue.async { [weak self] in
        guard let self = self else { return }

        self.session.beginConfiguration()

        // Switch to lowest quality preset
        if self.session.canSetSessionPreset(.low) {
          self.session.sessionPreset = .low
          self.logger.debug("Switched to low quality preset due to memory pressure")
        }

        self.session.commitConfiguration()
      }
    }
  }

  private func checkAndUpdatePermissions() {
    let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
    let wasGranted = permissionGranted
    previousPermissionState = permissionGranted
    permissionGranted = currentStatus == .authorized

    logger.debug(
      "Permission check: current=\(currentStatus.rawValue), permissionGranted=\(self.permissionGranted), previousState=\(self.previousPermissionState)"
    )

    // If permission status changed, update the session
    if wasGranted != permissionGranted {
      logger.debug("Permission status changed from \(wasGranted) to \(self.permissionGranted)")

      // If permission was just granted, start the session
      if permissionGranted {
        logger.debug("Permission newly granted, starting session")
        startSessionIfAuthorized { error in
          if let error = error {
            self.logger.error(
              "Failed to start session after permission change: \(error.localizedDescription)")
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
    permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
      [weak self] _ in
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

  public func start(
    _ requirePermissionsIfNeeded: Bool, delegate: AVCapturePhotoCaptureDelegate,
    completion: @escaping (Error?) -> Void
  ) {
    self.delegate = delegate
    start(requirePermissionsIfNeeded, completion: completion)
  }

  public func start(_ requirePermissionsIfNeeded: Bool, completion: @escaping (Error?) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined, .denied:
      if requirePermissionsIfNeeded {
        askForPermissionIfNeeded { err in
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
    case .restricted, .authorized:  // The user has previously granted access to the camera.
      permissionGranted = true

    // Combine the two other cases into the default case
    default:
      permissionGranted = false
    }
    return status
  }

  func startSessionIfAuthorized(completion: @escaping (Error?) -> Void) {
    if permissionGranted {
      sessionQueue.async { [unowned self] in
        self.setupCaptureSession(completion: completion)
        self.session.startRunning()
        logger.debug("Started session running. (startSessionIfAuthorized)")
        completion(nil)
      }
    } else {
      completion(
        CaptureError.notAuthorized(comment: "Not starting session due to missing permission"))
      logger.error("Not starting session due to missing permission")

      // Start monitoring for permission changes
      startPermissionMonitoring()
    }
  }

  private func updateSessionConfiguration() {
    sessionQueue.async { [weak self] in
      guard let self = self else { return }

      self.session.beginConfiguration()

      // Set session preset based on subdued mode
      if self.isSubdued {
        // Use a lower resolution preset
        if self.session.canSetSessionPreset(.medium) {
          self.session.sessionPreset = .medium
        }

        // Configure video input for lower frame rate
        if let videoInput = self.session.inputs.first as? AVCaptureDeviceInput {
          do {
            try videoInput.device.lockForConfiguration()

            // Set a lower frame rate
            if let format = videoInput.device.formats.first(where: { format in
              let description = format.formatDescription
              let dimensions = CMVideoFormatDescriptionGetDimensions(description)
              return dimensions.width <= 1280 && dimensions.height <= 720
            }) {
              videoInput.device.activeFormat = format

              // Set frame rate to 15fps in subdued mode
              let frameDuration = CMTime(value: 1, timescale: 15)
              // FIXME this blows up on macOS
              videoInput.device.activeVideoMinFrameDuration = frameDuration
              videoInput.device.activeVideoMaxFrameDuration = frameDuration
            }

            videoInput.device.unlockForConfiguration()
          } catch {
            self.logger.error(
              "Failed to configure video input for subdued mode: \(error.localizedDescription)")
          }
        }
      } else {
        // Restore to high quality settings
        if self.session.canSetSessionPreset(.high) {
          self.session.sessionPreset = .high
        }

        // Configure video input for normal frame rate
        if let videoInput = self.session.inputs.first as? AVCaptureDeviceInput {
          do {
            try videoInput.device.lockForConfiguration()

            // Restore to highest quality format
            if let format = videoInput.device.formats.max(by: { format1, format2 in
              let dim1 = CMVideoFormatDescriptionGetDimensions(format1.formatDescription)
              let dim2 = CMVideoFormatDescriptionGetDimensions(format2.formatDescription)
              return dim1.width * dim1.height < dim2.width * dim2.height
            }) {
              videoInput.device.activeFormat = format

              // Set frame rate to 30fps in normal mode
              let frameDuration = CMTime(value: 1, timescale: 30)
              videoInput.device.activeVideoMinFrameDuration = frameDuration
              videoInput.device.activeVideoMaxFrameDuration = frameDuration
            }

            videoInput.device.unlockForConfiguration()
          } catch {
            self.logger.error(
              "Failed to configure video input for normal mode: \(error.localizedDescription)")
          }
        }
      }

      self.session.commitConfiguration()
      self.logger.debug(
        "Session configuration updated for \(self.isSubdued ? "subdued" : "normal") mode")
    }
  }

  // Modify setupCaptureSession to respect subdued mode
  func setupCaptureSession(completion: @escaping (Error?) -> Void) {
    // Check if we're running on a Mac (Catalyst or simulator) - skip camera setup
    #if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
      logger.debug("Running on Mac environment - skipping camera setup")
      completion(
        CaptureError.deviceNotAvailable(comment: "Camera not available on Mac environment"))
      return
    #endif

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
      videoDevice =
        AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)
        ?? AVCaptureDevice.default(for: .video)
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

    // Set initial session preset based on subdued mode
    if isSubdued {
      if session.canSetSessionPreset(.medium) {
        session.sessionPreset = .medium
      }
    } else {
      if session.canSetSessionPreset(.high) {
        session.sessionPreset = .high
      }
    }

    // Configure session to discard late frames
    #if os(iOS)
      session.usesApplicationAudioSession = false
      session.automaticallyConfiguresApplicationAudioSession = false
      session.automaticallyConfiguresCaptureDeviceForWideColor = true
    #endif

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
    videoOutput.alwaysDiscardsLateVideoFrames = true
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
      if let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
      {
        NSWorkspace.shared.open(url)
        logger.debug("Opening macOS camera privacy settings")

        // Start monitoring for permission changes
        startPermissionMonitoring()
      }
    #endif
  }

  public func askForPermissionIfNeeded(completion: @escaping (Error?) -> Void) {
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
        break
      }
    } else {
      completion(nil)
    }
  }

  // called from view button
  public func askForPermission() async {
    logger.debug("Requesting camera access asynchronously")

    // Check if we're running on a Mac (Catalyst or simulator)
    #if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
      logger.debug("Running on Mac environment - skipping camera permission request")
      DispatchQueue.main.async {
        self.permissionGranted = false
        self.logger.debug("Camera access denied on Mac environment")
      }
      return
    #endif

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

    // Only try to start session if permission was granted
    guard granted else {
      logger.debug("Camera permission denied - not starting session")
      return
    }

    // Fixed continuation leak by ensuring it's always resumed
    await withCheckedContinuation { continuation in
      self.startSessionIfAuthorized { err in
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

      let photoCaptureProcessor = PhotoCaptureProcessorRef(
        with: settings,
        willCapturePhotoAnimation: {
          // Flash the screen to signal that a photo was taken
          DispatchQueue.main.async {
            self.logger.debug("Photo capture animation")
          }
        },
        livePhotoCaptureHandler: { capturing in
          self.logger.debug("Live photo capture: \(capturing ? "started" : "ended")")
        },
        completionHandler: { photoCaptureProcessor in
          self.logger.debug("Photo capture completed")
        },
        photoProcessingHandler: { animate in
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

  /// Pauses the camera stream without stopping the session
  public func pauseStream() {
    guard !isPaused else {
      logger.debug("Stream already paused")
      return
    }

    sessionQueue.async { [weak self] in
      guard let self = self else { return }

      if self.session.isRunning {
        self.session.stopRunning()
        self.logger.debug("Camera stream paused")

        // Stop session duration monitoring
        self.sessionDurationTimer?.invalidate()
        self.sessionDurationTimer = nil

        DispatchQueue.main.async {
          self.isPaused = true
        }
      }
    }
  }

  /// Resumes the camera stream if it was previously paused
  public func resumeStream() {
    guard isPaused else {
      logger.debug("Stream already running")
      return
    }

    sessionQueue.async { [weak self] in
      guard let self = self else { return }

      // Only proceed if we have permission
      guard self.permissionGranted else {
        self.logger.debug("Not resuming stream - no camera permission")
        return
      }

      // Reconfigure the session with fresh inputs and outputs
      self.setupCaptureSession { [weak self] error in
        guard let self = self else { return }

        if let error = error {
          self.logger.error("Failed to reconfigure session: \(error.localizedDescription)")
          return
        }

        if !self.session.isRunning {
          self.session.startRunning()
          self.logger.debug("Camera stream resumed")

          // Restart session duration monitoring
          self.setupSessionDurationMonitoring()

          DispatchQueue.main.async {
            self.isPaused = false
          }
        }
      }
    }
  }

  func cleanupCaptureResources() {
    sessionQueue.async { [weak self] in
      guard let self = self else { return }

      // Stop the session if it's running
      if self.session.isRunning {
        self.session.stopRunning()
        self.logger.debug("Capture session stopped")
      }

      // Remove all inputs and outputs
      self.session.beginConfiguration()

      // Remove all inputs
      for input in self.session.inputs {
        self.session.removeInput(input)
        self.logger.debug("Removed input: \(input)")
      }

      // Remove all outputs
      for output in self.session.outputs {
        self.session.removeOutput(output)
        self.logger.debug("Removed output: \(output)")
      }

      self.session.commitConfiguration()
      self.logger.debug("Capture session configuration cleaned up")

      // Clear the current frame
      if !self.leaveMostRecentFrameOnSleep {
        DispatchQueue.main.async {
          self.frame = nil
        }
      }
    }
  }

  #if os(iOS)
    private func setupOrientationTracking() {
      // Start device orientation monitoring
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()

      // Observe orientation changes
      orientationObserver = NotificationCenter.default.addObserver(
        forName: UIDevice.orientationDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.updateOrientation()
      }

      // Set initial orientation
      currentOrientation = UIDevice.current.orientation
      updateOrientation()
    }

    private func updateOrientation() {
      let newOrientation = UIDevice.current.orientation

      // Only update if orientation is valid
      guard newOrientation.isValidInterfaceOrientation else { return }

      currentOrientation = newOrientation
      logger.debug("Device orientation changed to: \(newOrientation.rawValue)")

      // Update video connection orientation
      sessionQueue.async { [weak self] in
        guard let self = self else { return }

        guard
          let videoOutput = self.session.outputs.first(where: { $0 is AVCaptureVideoDataOutput })
            as? AVCaptureVideoDataOutput,
          let connection = videoOutput.connection(with: .video)
        else {
          return
        }

        if connection.isVideoOrientationSupported {
          let videoOrientation: AVCaptureVideoOrientation
          switch currentOrientation {
          case .portrait:
            videoOrientation = .portrait
          case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
          case .landscapeLeft:
            videoOrientation = .landscapeRight
          case .landscapeRight:
            videoOrientation = .landscapeLeft
          default:
            videoOrientation = .portrait
          }

          connection.videoOrientation = videoOrientation
          logger.debug("Updated video orientation to: \(videoOrientation.rawValue)")
        }
      }
    }
  #endif
}

// Core Image sample buffer streaming
extension CaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {

  public func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
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
