import SwiftUI
import AVFoundation
import os

public struct CameraSwitcher: View {
    @ObservedObject public var captureService: CaptureService
    public let designSystem: DesignSystemSetup
    
    private let logger = Logger(subsystem: "com.record-thing", category: "CameraSwitcher")

    public init(captureService: CaptureService, designSystem: DesignSystemSetup) {
        self.captureService = captureService
        self.designSystem = designSystem
    }
    
    public var body: some View {
        HStack(spacing: designSystem.standardSpacing) {
            #if os(macOS)
            Menu {
                ForEach(availableCameras, id: \.uniqueID) { camera in
                    Button(action: {
                        switchToCamera(camera)
                    }) {
                        HStack {
                            Text(camera.localizedName)
                            if isCurrentCamera(camera) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "camera.fill")
                    .foregroundColor(designSystem.accentColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(designSystem.backgroundColor)
                            .shadow(radius: designSystem.shadowRadius)
                    )
            }
            #else
            Button(action: {
                switchToNextCamera()
            }) {
                Image(systemName: "camera.rotate.fill")
                    .foregroundColor(designSystem.accentColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(designSystem.backgroundColor)
                            .shadow(radius: designSystem.shadowRadius)
                    )
            }
            #endif
        }
    }
    
    // MARK: - Camera Management
    
    private var availableCameras: [AVCaptureDevice] {
        #if os(macOS)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices
        #else
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices
        #endif
    }
    
    private func isCurrentCamera(_ device: AVCaptureDevice) -> Bool {
        guard let currentInput = captureService.session.inputs.first as? AVCaptureDeviceInput else {
            return false
        }
        return currentInput.device.uniqueID == device.uniqueID
    }
    
    private func switchToCamera(_ device: AVCaptureDevice) {
        logger.debug("Switching to camera: \(device.localizedName)")
        
        // Configure the new camera
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
            
            // Create new input
            let newInput = try AVCaptureDeviceInput(device: device)
            
            // Begin configuration
            captureService.session.beginConfiguration()
            
            // Remove existing inputs
            for input in captureService.session.inputs {
                captureService.session.removeInput(input)
            }
            
            // Add new input
            if captureService.session.canAddInput(newInput) {
                captureService.session.addInput(newInput)
                logger.debug("Successfully switched to camera: \(device.localizedName)")
            } else {
                logger.error("Could not add new camera input")
            }
            
            // Commit configuration
            captureService.session.commitConfiguration()
            
        } catch {
            logger.error("Failed to switch camera: \(error.localizedDescription)")
        }
    }
    
    private func switchToNextCamera() {
        guard let currentInput = captureService.session.inputs.first as? AVCaptureDeviceInput,
              let currentIndex = availableCameras.firstIndex(where: { $0.uniqueID == currentInput.device.uniqueID }) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % availableCameras.count
        switchToCamera(availableCameras[nextIndex])
    }
}

#if DEBUG
struct CameraSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CameraSwitcher(
                captureService: CaptureService(),
                designSystem: .light
            )
        }
        .padding()
        .background(Color.gray)
    }
}
#endif 