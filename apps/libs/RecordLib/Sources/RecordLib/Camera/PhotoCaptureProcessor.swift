//
//  PhotoCaptureDelegate.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 23.07.23.
//

import AVFoundation
import Foundation
import os

#if os(macOS)
  import AppKit
  import CoreLocation
#else
  import Photos
  import UIKit
#endif

class PhotoCaptureProcessor: NSObject {
  // MARK: - Properties

  private(set) var requestedPhotoSettings: AVCapturePhotoSettings
  private let logger = Logger(subsystem: "com.record-thing", category: "camera")

  // Save the location of captured photos
  var location: CLLocation?

  // MARK: - Initialization

  init(with requestedPhotoSettings: AVCapturePhotoSettings) {
    self.requestedPhotoSettings = requestedPhotoSettings
    super.init()
    logger.debug("PhotoCaptureProcessor initialized")
  }

  // MARK: - Image Saving

  func saveImage(image: RecordImage, name: String) {
    // Use memory-aware compression quality
    let compressionQuality: CGFloat = MemoryMonitor.shared.isMemoryConstrainedDevice() ? 0.7 : 0.95

    // Use the recordJpegData method from RecordImage extension
    guard let data = image.recordJpegData(compressionQuality: compressionQuality) else {
      logger.error("Error getting JPEG data for \(name)")
      return
    }

    // Get appropriate directory based on platform
    #if os(macOS)
      let directory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
    #else
      let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    #endif

    if let str = directory?.absoluteString {
      logger.debug("Saving to directory: \(str)")
    }

    guard let path = directory?.appendingPathComponent("\(name).jpg", conformingTo: .jpeg) else {
      logger.error("Path construction failed")
      return
    }

    do {
      try data.write(to: path)
      logger.debug("Image saved successfully to \(path.path)")
    } catch let error {
      logger.error("Could not save image: \(error.localizedDescription)")
    }
  }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
  func photoOutput(
    _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
  ) {
    #if os(iOS)
      logger.debug("Photo processing completed with metadata: \(photo.metadata)")
    #endif

    if let error = error {
      logger.error("Error processing photo: \(error.localizedDescription)")
      return
    }

    guard let data = photo.fileDataRepresentation() else {
      logger.error("Couldn't make a Photo from the camera information")
      return
    }

    #if os(macOS)
      guard let image = NSImage(data: data) else {
        logger.error("Image wrapping failed")
        return
      }
    #else
      guard let image = UIImage(data: data) else {
        logger.error("Image wrapping failed")
        return
      }
    #endif

    saveImage(image: image, name: "new image")
    // TODO evaluate the image

    // let session continue
  }
}

class PhotoCaptureProcessorRef: NSObject {
  // MARK: - Properties

  private(set) var requestedPhotoSettings: AVCapturePhotoSettings
  private let logger = Logger(subsystem: "com.record-thing", category: "camera")

  private let willCapturePhotoAnimation: () -> Void
  private let livePhotoCaptureHandler: (Bool) -> Void
  private let completionHandler: (PhotoCaptureProcessorRef) -> Void
  private let photoProcessingHandler: (Bool) -> Void

  lazy var context = CIContext()

  private var photoData: Data?
  private var livePhotoCompanionMovieURL: URL?
  private var portraitEffectsMatteData: Data?
  private var semanticSegmentationMatteDataArray = [Data]()
  private var maxPhotoProcessingTime: CMTime?

  // Save the location of captured photos
  var location: CLLocation?

  // MARK: - Initialization

  init(
    with requestedPhotoSettings: AVCapturePhotoSettings,
    willCapturePhotoAnimation: @escaping () -> Void,
    livePhotoCaptureHandler: @escaping (Bool) -> Void,
    completionHandler: @escaping (PhotoCaptureProcessorRef) -> Void,
    photoProcessingHandler: @escaping (Bool) -> Void
  ) {
    self.requestedPhotoSettings = requestedPhotoSettings
    self.willCapturePhotoAnimation = willCapturePhotoAnimation
    self.livePhotoCaptureHandler = livePhotoCaptureHandler
    self.completionHandler = completionHandler
    self.photoProcessingHandler = photoProcessingHandler
    super.init()
    logger.debug("PhotoCaptureProcessorRef initialized")
  }

  // MARK: - Cleanup

  private func didFinish() {
    if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
      if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
        do {
          try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
        } catch {
          logger.error("Could not remove file at url: \(livePhotoCompanionMoviePath)")
        }
      }
    }

    completionHandler(self)
  }
}

#if os(iOS)
  extension PhotoCaptureProcessorRef: AVCapturePhotoCaptureDelegate {
    /*
     This extension adopts all of the AVCapturePhotoCaptureDelegate protocol methods.
     */

    /// - Tag: WillBeginCapture
    func photoOutput(
      _ output: AVCapturePhotoOutput,
      willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
      if resolvedSettings.livePhotoMovieDimensions.width > 0
        && resolvedSettings.livePhotoMovieDimensions.height > 0
      {
        livePhotoCaptureHandler(true)
      }
      maxPhotoProcessingTime =
        resolvedSettings.photoProcessingTimeRange.start
        + resolvedSettings.photoProcessingTimeRange.duration
    }

    /// - Tag: WillCapturePhoto
    func photoOutput(
      _ output: AVCapturePhotoOutput,
      willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
      willCapturePhotoAnimation()

      guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
        return
      }

      // Show a spinner if processing time exceeds one second.
      let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
      if maxPhotoProcessingTime > oneSecond {
        photoProcessingHandler(true)
      }
    }

    func handleMatteData(_ photo: AVCapturePhoto, ssmType: AVSemanticSegmentationMatte.MatteType) {

      // Find the semantic segmentation matte image for the specified type.
      guard var segmentationMatte = photo.semanticSegmentationMatte(for: ssmType) else { return }

      // Retrieve the photo orientation and apply it to the matte image.
      if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
        let exifOrientation = CGImagePropertyOrientation(rawValue: orientation)
      {
        // Apply the Exif orientation to the matte image.
        segmentationMatte = segmentationMatte.applyingExifOrientation(exifOrientation)
      }

      var imageOption: CIImageOption!

      // Switch on the AVSemanticSegmentationMatteType value.
      switch ssmType {
      case .hair:
        imageOption = .auxiliarySemanticSegmentationHairMatte
      case .skin:
        imageOption = .auxiliarySemanticSegmentationSkinMatte
      case .teeth:
        imageOption = .auxiliarySemanticSegmentationTeethMatte
      //        case .glasses:
      //            imageOption = .auxiliarySemanticSegmentationGlassesMatte
      default:
        logger.warning("This semantic segmentation type is not supported!")
        return
      }

      guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }

      // Create a new CIImage from the matte's underlying CVPixelBuffer.
      let ciImage = CIImage(
        cvImageBuffer: segmentationMatte.mattingImage,
        options: [
          imageOption: true,
          .colorSpace: perceptualColorSpace,
        ])

      // Get the HEIF representation of this image.
      guard
        let imageData = context.heifRepresentation(
          of: ciImage,
          format: .RGBA8,
          colorSpace: perceptualColorSpace,
          options: [.depthImage: ciImage])
      else { return }

      // Add the image data to the SSM data array for writing to the photo library.
      semanticSegmentationMatteDataArray.append(imageData)
    }

    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(
      _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
    ) {
      photoProcessingHandler(false)

      if let error = error {
        logger.error("Error capturing photo: \(error.localizedDescription)")
        return
      } else {
        photoData = photo.fileDataRepresentation()
      }
      // A portrait effects matte gets generated only if AVFoundation detects a face.
      if var portraitEffectsMatte = photo.portraitEffectsMatte {
        if let orientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32 {
          portraitEffectsMatte = portraitEffectsMatte.applyingExifOrientation(
            CGImagePropertyOrientation(rawValue: orientation)!)
        }
        let portraitEffectsMattePixelBuffer = portraitEffectsMatte.mattingImage
        let portraitEffectsMatteImage = CIImage(
          cvImageBuffer: portraitEffectsMattePixelBuffer,
          options: [.auxiliaryPortraitEffectsMatte: true])

        guard let perceptualColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
          portraitEffectsMatteData = nil
          return
        }
        portraitEffectsMatteData = context.heifRepresentation(
          of: portraitEffectsMatteImage,
          format: .RGBA8,
          colorSpace: perceptualColorSpace,
          options: [.portraitEffectsMatteImage: portraitEffectsMatteImage])
      } else {
        portraitEffectsMatteData = nil
      }

      for semanticSegmentationType in output.enabledSemanticSegmentationMatteTypes {
        handleMatteData(photo, ssmType: semanticSegmentationType)
      }

      #if os(macOS)
        // On macOS, we'll just save the image to the Pictures directory
        if let photoData = photoData, let image = NSImage(data: photoData) {
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
          let filename = "RecordThing-\(formatter.string(from: Date()))"
          saveImage(image: image, name: filename)
        }
        didFinish()
      #endif
    }

    /// - Tag: DidFinishRecordingLive
    func photoOutput(
      _ output: AVCapturePhotoOutput,
      didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL,
      resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
      livePhotoCaptureHandler(false)
    }

    /// - Tag: DidFinishProcessingLive
    func photoOutput(
      _ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
      duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings,
      error: Error?
    ) {
      if error != nil {
        logger.error("Error processing Live Photo companion movie: \(String(describing: error))")
        return
      }
      livePhotoCompanionMovieURL = outputFileURL
    }

    /// - Tag: DidFinishCapture
    func photoOutput(
      _ output: AVCapturePhotoOutput,
      didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?
    ) {
      if let error = error {
        logger.error("Error capturing photo: \(error.localizedDescription)")
        didFinish()
        return
      }

      guard let photoData = photoData else {
        logger.error("No photo data resource")
        didFinish()
        return
      }

      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          PHPhotoLibrary.shared().performChanges(
            {
              let options = PHAssetResourceCreationOptions()
              let creationRequest = PHAssetCreationRequest.forAsset()
              options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map {
                $0.rawValue
              }
              creationRequest.addResource(with: .photo, data: photoData, options: options)

              // Specify the location the photo was taken
              creationRequest.location = self.location

              if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
                let livePhotoCompanionMovieFileOptions = PHAssetResourceCreationOptions()
                livePhotoCompanionMovieFileOptions.shouldMoveFile = true
                creationRequest.addResource(
                  with: .pairedVideo,
                  fileURL: livePhotoCompanionMovieURL,
                  options: livePhotoCompanionMovieFileOptions)
              }

              // Save Portrait Effects Matte to Photos Library only if it was generated
              if let portraitEffectsMatteData = self.portraitEffectsMatteData {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(
                  with: .photo,
                  data: portraitEffectsMatteData,
                  options: nil)
              }
              // Save Portrait Effects Matte to Photos Library only if it was generated
              for semanticSegmentationMatteData in self.semanticSegmentationMatteDataArray {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(
                  with: .photo,
                  data: semanticSegmentationMatteData,
                  options: nil)
              }

            },
            completionHandler: { _, error in
              if let error = error {
                self.logger.error(
                  "Error occurred while saving photo to photo library: \(error.localizedDescription)"
                )
              }

              self.didFinish()
            }
          )
        } else {
          self.didFinish()
        }
      }
    }

    // MARK: - Helper Methods

    /// Saves an image to disk
    private func saveImage(image: RecordImage, name: String) {
      // Use the recordJpegData method from RecordImage extension
      guard let data = image.recordJpegData(compressionQuality: 0.95) else {
        logger.error("Error getting JPEG data for \(name)")
        return
      }

      // Get appropriate directory based on platform
      #if os(macOS)
        let directory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
      #else
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
      #endif

      if let str = directory?.absoluteString {
        logger.debug("Saving to directory: \(str)")
      }

      guard let path = directory?.appendingPathComponent("\(name).jpg", conformingTo: .jpeg) else {
        logger.error("Path construction failed")
        return
      }

      do {
        try data.write(to: path)
        logger.debug("Image saved successfully to \(path.path)")
      } catch let error {
        logger.error("Could not save image: \(error.localizedDescription)")
      }
    }
  }
#endif
