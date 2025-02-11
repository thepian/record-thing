//
//  CameraCapture+Video.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 14.11.2023.
//

import Foundation
import AVFoundation
import CoreImage
import Vision
import UIKit

extension VisionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Core Image sample buffer streaming
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if detectionBusy { return }
        detectionBusy = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }
        
        /*
         Perhaps have an outstanding job counter that will end with a publish of the new state to ViewModel
         */
        if detectFaces || detectBarcodes || detectDocuments {
            // Cleaner to wrap in @Actor ? https://blog.devgenius.io/how-to-use-mainactor-and-globalactor-d5fd3794903d
            DispatchQueue.global(qos: .userInitiated).async {
                self.detectOrTrack(pixelBuffer)
            }
        } else if nextRenderTime < Date.now {
            // TODO this is to avoid leaking (ideally detectOrTrack wouldn't leak when run in global DispatchQueue !?
//            let cgFrame = annotateFrame(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            let cgFrame = ciToCgImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer), ciContext: ciContext)
            
            // All UI updates should be/ must be performed on the main queue.
            DispatchQueue.main.async { [unowned self] in
                if let model = self.model {
                    if let frame = cgFrame {
                        model.frame = frame
                    }
                }
                nextRenderTime = Date(timeIntervalSinceNow: 0.02) // render at max 50 FPS
                self.detectionBusy = false // async / await ?
            }
        } else {
            self.detectionBusy = false
        }

    }
    
    func detectOrTrack(_ pixelBuffer: CVImageBuffer) {
        // All UI updates should be/ must be performed on the main queue.
        let cgFrame = ciToCgImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer), ciContext: ciContext)
        DispatchQueue.main.async { [unowned self] in
            if let model = self.model {
                if let frame = cgFrame {
                    model.frame = frame
                }
            }
            self.detectionBusy = false // TODO completion handler / await
        }

    }
    
    /*
     Called by the starting of the Capture session to prepare recognition.
     */
    func prepareVision() {
//        if detectFaces { detectFaceRequest() }
//        if detectBarcodes { detectBarcodesRequest() }
//        if detectDocuments { detectDocumentRectangleRequest() }
    }

    func setupVideoCaptureSession() {
        // TODO capture front & back
        
        // https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Cameras/Cameras.html
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) ?? AVCaptureDevice.default(for: .video) else {
            print("no back camera found")
            return
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
    }
        
    // TODO dynamic capture modes based on situation addOutput / removeOutput
    // This will save a lot of CPU, memory and battery
    
    func setupVideoRecordingSession() {
        // Output to FrameView
        let videoOutput = AVCaptureVideoDataOutput()
        // ML required uncompressed BGRA (https://developer.apple.com/documentation/technotes/tn3121-selecting-a-pixel-format-for-an-avcapturevideodataoutput)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        
        // This consumes a significant amount of memory
//        if session.canAddOutput(videoOutput) {
//            session.addOutput(videoOutput)
//        }
        
// TODO        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }
}
