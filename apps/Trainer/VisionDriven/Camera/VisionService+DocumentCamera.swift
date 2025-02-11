//
//  CameraCapture+DocumentCamera.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 14.11.2023.
//

import Foundation
import VisionKit

extension VisionService: VNDocumentCameraViewControllerDelegate {
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        print("DocumentCamera finished", scan.description)
    }
    
    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        print("DocumentCamera cancelled by user")
    }
}

