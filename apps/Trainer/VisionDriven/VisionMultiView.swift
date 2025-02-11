//
//  VisionMultiView.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 19.11.2023.
//

import SwiftUI
import ARKit

public struct VisionMultiView<Background: View>: View {
    
//    @State var pageTabViewStyle = PageTabViewStyle(indexDisplayMode: .never)
    
//    let data = []
    
    var model: VDViewModel
    var service: VisionService
    var BackgroundViews: () -> Background
    
    public init(model: VDViewModel, service: VisionService, @ViewBuilder background: @escaping () -> Background) {
        self.model = model
        self.service = service
        self.BackgroundViews = background
    }
    
    public var body: some View {
        ZStack {
            BackgroundViews()
            switch model.cameraView {
            case .Standard:
                VisionPreview(service: service)
                    .ignoresSafeArea()
                    .frame(width: UIScreen.main.bounds.width,
                           height: UIScreen.main.bounds.height)
                    .offset(x: 0, y: -12) // FIXME
            case .AR:
                if ARConfiguration.isSupported { // TODO preference for session
                    CustomARViewRepresentable()
                }
            case .iOSDocument:
                DocumentCamera(
                    cancelAction: {  }, resultAction: { _ in })
                    .environmentObject(model)
            }
         WebAppView(model: model, visionService: service).ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    @StateObject var model = VDViewModel()
    @StateObject var service = VisionService()
    
    return VisionMultiView(model: model, service: service, background: { Color.red })
}
