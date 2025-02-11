//
//  SimpleCameraView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 16.07.23.
//

import SwiftUI

// https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameView.swift
public struct SimpleCameraView: View {
    var model: VDViewModel
    var image: CGImage?
    private let label = Text("Live video frame")
    
    public init(model: VDViewModel) {
        self.model = model
    }
    
    public init(model: VDViewModel, image: CGImage?) {
        self.model = model
        self.image = image
    }
    
    public var body: some View {
        if let image = image {
            Image(image, scale: 1.0, orientation: .up, label: label)
        } else {
            VStack {
                Image(model.bgImageSet)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }.frame(maxWidth: UIScreen.main.bounds.size.width, maxHeight: UIScreen.main.bounds.size.height)
        }
    }
}

struct SimpleCameraView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var model = VDViewModel()
        SimpleCameraView(model: model)
    }
}
