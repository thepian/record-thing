//
//  VDViewModel+Permissions.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 28.10.2023.
//

import Foundation
import AVFoundation

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



extension VDViewModel {
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    

    func reflectPermission() {
        let status = checkPermission()
        reflectCaptureDevice(status: status)
    }
    
    // refine
    func checkPermission() -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .restricted, .authorized: // The user has previously granted access to the camera.
            permissionGranted = true
            
            // Combine the two other cases into the default case
        default:
            permissionGranted = false
        }
        return status
    }
    
    // refine
    func reflectCaptureDevice(status: AVAuthorizationStatus) {
        switch status {
            case .authorized:
//                self.onboardingState = OnboardingState.ShowAdvice
                self.showTopBar = true
//                self.videoCaptureEnabled = true
//                self.videoCaptureCTA = false
//                self.showBelongings = true
//                setAdvice(1)
            case .notDetermined:
//                self.onboardingState = OnboardingState.PermitVideoCapture
                self.showTopBar = false
//                self.videoCaptureEnabled = false
//                self.videoCaptureCTA = true
//                self.showBelongings = false
//                setAdvice(0, showVideoAuthButton: true)
            default: // .denied .restricted
//                self.onboardingState = OnboardingState.CaptureInAppSettings
                self.showTopBar = true
//                self.videoCaptureEnabled = false
//                self.videoCaptureCTA = false // or can it be done for .restricted?
//                self.showBelongings = true
//                setAdvice(1, showOpenSettingsButton: true)
        }
    }
    
    func setAdvice(_ index: Int, showVideoAuthButton: Bool = false, showOpenSettingsButton: Bool = false) {
//        self.adviceIconName = adviceSteps[index].iconName
//        self.adviceText = adviceSteps[index].text
    }
}
