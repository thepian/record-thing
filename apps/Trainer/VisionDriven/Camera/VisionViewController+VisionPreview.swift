//
//  File.swift
//  
//
//  Created by Henrik Vendelbo on 18.11.2023.
//

import AVFoundation
import UIKit
import SwiftUI

class VisionViewController: UIViewController {
//    var session: Binding<AVCaptureSession>
    // TODO sessionQueue
    // TODO vision state (show frame, annotate it)
    
    weak var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    init(service: VisionService) {
        captureSession = service.session

        super.init(nibName: nil, bundle: nil)
//        wantsFullScreenLayout = true
        
    }
    
//    init(_ session: Binding<AVCaptureSession>) {
//        self.session = session
//        super.init(nibName: nil, bundle: nil)
//    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    public override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        view.frame = view.superview?.bounds //.bounds
//    }
    
    public override func viewDidLoad() {
//        view.scrollView.contentInset = UIEdgeInsets.init(top: 0,left: 0,bottom: 0,right: 0)
        super.viewDidLoad()
        
//        view.autoresizingMask =
//        view.insetsLayoutMarginsFromSafeArea = false
        
        // FIXME magic value
        // Why the 20px gap at the top of my UIViewController?
        // https://stackoverflow.com/questions/30525403/why-the-20px-gap-at-the-top-of-my-uiviewcontroller
        view.frame.origin.y = -20 // .inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        
//        view.backgroundColor = UIColor.blue
//        captureSession = AVCaptureSession()

//        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
//        let videoInput: AVCaptureDeviceInput
//
//        do {
//            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
//        } catch {
//            return
//        }
//
//        if (captureSession.canAddInput(videoInput)) {
//            captureSession.addInput(videoInput)
//        } else {
//            failed()
//            return
//        }
//
//        let metadataOutput = AVCaptureMetadataOutput()
//
//        if (captureSession.canAddOutput(metadataOutput)) {
//            captureSession.addOutput(metadataOutput)
//
//            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//            metadataOutput.metadataObjectTypes = [.qr, .ean13, .code128]
//
//        } else {
//            failed()
//            return
//        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
//        previewLayer.frame = CGRect(x: 20, y: 60, width: 335, height: 200)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

//        captureSession.startRunning()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
//        sessionQueue.async {
//            if self.setupResult == .success {
//                self.session.stopRunning()
//                self.isSessionRunning = self.session.isRunning
//                self.removeObservers()
//            }
//        }
        
        super.viewWillDisappear(animated)
    }
}

// SwiftUI support
struct VisionPreview: UIViewControllerRepresentable {
    
    public typealias UIViewControllerType = VisionViewController

    var service: VisionService

    init(service: VisionService) {
        self.service = service
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VisionPreview>) -> VisionViewController {
        
        return VisionViewController(service: service) 
    }
    
    func updateUIViewController(_ uiViewController: VisionViewController, context: UIViewControllerRepresentableContext<VisionPreview>) {
        
    }
}
