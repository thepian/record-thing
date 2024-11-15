//
//  DocumentCamera.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 02.07.23.
//


import SwiftUI
import VisionKit

/**
 This view can be used to open a camera that can scan one or
 multiple pages in a physical document.

 You create a document camera by providing two action blocks:
 
 ```swift
 let camera = DocumentCamera(
    cancelAction: { print("User did cancel") }  // Optional
    resultAction: { result in ... }             // Mandatory
 }
 ```

 You can then present the camera with a sheet, a full screen
 cover etc.

 The camera uses a `VNDocumentCameraViewController` and will
 return a `VNDocumentCameraScan` that contains a list of all
 scanned document pages, if any.
 */
public struct DocumentCamera: UIViewControllerRepresentable {
    @EnvironmentObject var model: VDViewModel

    public init(
        cancelAction: @escaping CancelAction = {},
        resultAction: @escaping ResultAction) {
        self.cancelAction = cancelAction
        self.resultAction = resultAction
    }
    
    public typealias CameraResult = Result<VNDocumentCameraScan, Error>
    public typealias CancelAction = () -> Void
    public typealias ResultAction = (CameraResult) -> Void
    
    private let cancelAction: CancelAction
    private let resultAction: ResultAction
        
    let controller = VNDocumentCameraViewController()

    
    public func documentDelegate(_ delegate: VNDocumentCameraViewControllerDelegate) -> DocumentCamera {
        controller.delegate = delegate
        return self
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
//        controller.delegate = context.coordinator
        return controller
    }
    
    public func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context) {}
}
