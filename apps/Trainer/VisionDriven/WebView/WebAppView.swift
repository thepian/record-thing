//
//  WebAppView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 01.07.23.
//

import SwiftUI
 
public struct WebAppView: UIViewControllerRepresentable {
    public var model: VDViewModel
    public var visionService: VisionService
    
    public init(model: VDViewModel, visionService: VisionService) {
        self.model = model
        self.visionService = visionService
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<WebAppView>) -> some UIViewController {
        let viewController = VDBridgeViewController()
        viewController.model = model // this seems to fail
        viewController.visionService = visionService
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<WebAppView>) {
        
    }
}

struct WebAppView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var captureAuthorizedView = VDViewModel()
        @StateObject var visionService = VisionService()
        // TODO set model on visionService, how?

        WebAppView(model: captureAuthorizedView as VDViewModel, visionService: visionService)
    }
}

