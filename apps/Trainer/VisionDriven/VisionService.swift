//
//  VisionService.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 26.10.2023.
//

import Foundation
import SwiftUI
import AVFoundation
import Vision


public class VisionService: NSObject, ObservableObject {
    weak public var model: VDViewModel?

    let ciContext = CIContext()

    // MARK: Session
    var autoRunSession = true
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    var session = AVCaptureSession()  // Should be possible to reuse the capture session
    var sessionConfigured = false
    
    // QRCode etc scanning
    let metadataOutput = AVCaptureMetadataOutput()
    let metadataObjectsQueue = DispatchQueue(label: "metadata objects queue", attributes: [], target: nil)
    let metadataObjectsSemaphore = DispatchSemaphore(value: 1)
    var metadataOutputEnabled: Bool = false
    
    // Photo & Video evidence
    var photoOutputEnabled = false
    var videoOutputEnabled = false
    //    var delegate: AVCapturePhotoCaptureDelegate?

    // Camera Features (interface CameraFeatures)
    var faceDetection: Bool = false
    var documentDetection: Bool = false
    var iOSDocumentDetection: Bool = false
    var appCodeDetection: Bool = true
    var otherCodeDetection: Bool = false
    var reality: Bool = false
    

    // Vision detection/tracking requests
    var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    var documentRequest: VNImageBasedRequest?
    var barcodeRequest: VNDetectBarcodesRequest?
    var faceTrackingRequests = [VNTrackObjectRequest]()
    var documentTrackingRequests = [VNTrackRectangleRequest]()
    var barcodeTrackingRequests = [VNTrackObjectRequest]()
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()


    // Observed Objects
    var observedPerson = [ObservedPerson]()
//    var mainObservedObject: ObservedObject?
    var observedBarcodes = [ObservedBarcode]()
    var observedObjects = [UUID: ObservedObject]()


    // MARK:  Detection loop control
    var detectionBusy = false
    var nextDetectTime = Date.now
    var nextTrackTime = Date.now
    var nextRenderTime = Date.now
    let detectFaces = false
    let detectDocuments = false
    let trackDocuments = false // The tracking seems to break something internally. Perhaps they need different handlers
    let detectBarcodes = false // true
    let outlineBarcodes = true
    let outlineDocuments = true
    let outlineText = false
    let showObject = true
    let annotationLineWidth = 10 / UIScreen.main.scale
    let useAnalyzer = false
    var symbologies: [VNBarcodeSymbology] = [.codabar, .qr] // use [] for all barcodes

    // Neural Engine check
    #if canImport(MLCompute)
    let useDocumentSegmentation = true // (MLCDevice.ane() != nil)
    #else
    let useDocumentSegmentation = false
    #endif

    func forgetVision() {
        faceTrackingRequests = [VNTrackObjectRequest]()
        documentTrackingRequests = [VNTrackRectangleRequest]()
        barcodeTrackingRequests = [VNTrackObjectRequest]()
        // TODO clean up requests for leaks?
        documentRequest = nil
        faceDetectionRequest = nil
        barcodeRequest = nil
        sequenceRequestHandler = VNSequenceRequestHandler()
    }
    
}
