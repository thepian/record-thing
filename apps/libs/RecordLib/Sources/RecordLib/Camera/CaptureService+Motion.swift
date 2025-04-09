//
//  CaptureService+Motion.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 09.04.2025.
//
import CoreMotion
import os

#if os(macOS)
import AppKit
#endif

extension CaptureService {
    
    // MARK: - Motion Detection
    
    func setupMotionDetection() {
        #if os(iOS)
        // iOS implementation using CMMotionManager
        guard motionManager.isAccelerometerAvailable else {
            logger.debug("Accelerometer not available")
            return
        }
        
        // Configure motion manager
        motionManager.accelerometerUpdateInterval = accelerometerUpdateInterval
        
        // Start motion updates
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Accelerometer error: \(error.localizedDescription)")
                return
            }
            
            guard let acceleration = data?.acceleration else { return }
            
            // Calculate total acceleration
            let totalAcceleration = sqrt(
                pow(acceleration.x, 2) +
                pow(acceleration.y, 2) +
                pow(acceleration.z, 2)
            )
            
            // Check if motion exceeds threshold
            if totalAcceleration > self.motionThreshold {
                self.handleMotionDetected()
                logger.debug("Motion detected \(totalAcceleration)")
            }
        }
        #else
        // macOS implementation using NSEvent
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { [weak self] event in
            guard let self = self else { return event }
            
            self.lastMouseMoveTime = Date()
            self.handleMotionDetected()
            logger.debug("Mouse movement detected")
            
            return event
        }
        #endif
        
        // Setup motion timeout timer
        motionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkMotionTimeout()
        }
        
        // Setup session duration monitoring
        setupSessionDurationMonitoring()
    }
    
    private func setupSessionDurationMonitoring() {
        // Start monitoring session duration
        sessionStartTime = Date()
        sessionDurationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkSessionDuration()
        }
    }
    
    private func checkSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        if sessionDuration >= defaultSessionDuration {
            logger.debug("Session duration exceeded \(self.defaultSessionDuration) seconds, restarting capture")
            restartCaptureSession()
        }
    }
    
    private func restartCaptureSession() {
        logger.debug("Restarting capture session")
        
        // Clean up current session
        cleanupCaptureResources()
        
        // Reset session start time
        sessionStartTime = Date()
        
        // Restart the session
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only proceed if we have permission
            guard self.permissionGranted else {
                self.logger.debug("Not restarting session - no camera permission")
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
                    self.logger.debug("Capture session restarted")
                    
                    DispatchQueue.main.async {
                        self.isPaused = false
                    }
                }
            }
        }
    }
    
    private func handleMotionDetected() {
        lastMotionTime = Date()
        
        // Resume capture if paused
        if isPaused {
            logger.debug("Motion detected, resuming capture")
            resumeStream()
        }
    }
    
    private func checkMotionTimeout() {
        let timeSinceLastMotion = Date().timeIntervalSince(lastMotionTime)

        if timeSinceLastMotion > motionTimeout && !isPaused {
            logger.debug("No motion detected for \(timeSinceLastMotion) seconds, pausing capture")
            pauseStream()
        }
    }
}

