//
//  VisionService+Permissions.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 26.10.2023.
//

import Foundation
import UIKit
import AVFoundation

/**
 * Tracks required user interactions needed before being able to use the app fully
 */
public struct VisionInstallationState {
    public var permissionGranted: Bool
    public var permissionDenied: Bool
    public var introduction: Bool
    public var authToken: String
}


public struct CameraFeatures {
  public var faceDetection: Bool

  /**
   * Vision plaform will detect documents and capture the information
   */
    public var documentDetection: Bool

  /**
   * iOS document detection framework driven
   */
    public var iOSDocumentDetection: Bool

  /**
   * QR code detection for installing
   */
    public var appCodeDetection: Bool

  // WebApp handled customCodeDetection?: boolean;

    public var reality: Bool
}


extension VisionService {
    public func openAppSettings() {
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil) // TODO completion update permissions
            }
        }
    }
    
    public func getInstallationState() -> VisionInstallationState {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let introduction = true // TODO from realm via model
        let authToken = "abcd" // TODO from realm
        
        return VisionInstallationState(permissionGranted: status == .authorized, permissionDenied: status == .denied, introduction: introduction, authToken: authToken)
    }

    public func askForPermissionIfNeeded(completion: @escaping (Error?) -> ()) {
        if model?.permissionGranted != true {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .restricted, .authorized:
                model?.permissionGranted = true
                completion(nil)
                
            case .denied:
                openAppSettings()
                // TODO poll permission
                
            case .notDetermined:
                // Strong reference not a problem here but might become one in the future.
                print("Requesting access.")
                AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                    self.model?.permissionGranted = granted
                    print("Permitted access.")
                    completion(nil)
                }
            default:
                break;
            }
        }
    }
    
    /*
    // called from view button
    func askForPermission() async {
        await AVCaptureDevice.requestAccess(for: .video)
        // TODO fix this leaks the continuation
        await withCheckedContinuation { continuation in
            self.startSessionIfAuthorized() { err in
                continuation.resume()
            }
        }
    }*/
}
