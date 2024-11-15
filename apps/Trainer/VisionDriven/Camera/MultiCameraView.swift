//
//  MultiCameraView.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 14.11.2023.
//

import SwiftUI
import VisionKit
import ARKit

// TODO use VisionMultiView instead

public struct MultiCameraView : View {
    public var model: VDViewModel
    public var visionService: VisionService
    let enableDocumentCamera = true
    let enableARCamera = true

    public init(model: VDViewModel, visionService: VisionService) {
        self.model = model
        self.visionService = visionService
    }
    
    public var body: some View {
        if model.showCameraView {
            TabView {
                SimpleCameraView(model: model, image: model.frame) // TODO should this be $model.frame based, does it leak?
                if VNDocumentCameraViewController.isSupported && enableDocumentCamera {
                    DocumentCamera(
                        cancelAction: {},
                        resultAction: { (result: DocumentCamera.CameraResult) in
                        })
                    .documentDelegate(visionService)
                }
                if ARConfiguration.isSupported && enableARCamera { // TODO preference for session
                    CustomARViewRepresentable()
                        .ignoresSafeArea()
                }
            }
            .ignoresSafeArea()
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

import AVFoundation



struct MultiCameraView_Previews: PreviewProvider {
    static var previews: some View {
        
        @StateObject var model = VDViewModel()
                
        ZStack {
            MultiCameraView(model: model, visionService: VisionService())
        }
        .environmentObject(model)
        .previewDisplayName("With Info")
        
        MultiCameraView(model: model, visionService: VisionService())
            .previewDisplayName("Just the View")
    }
}

