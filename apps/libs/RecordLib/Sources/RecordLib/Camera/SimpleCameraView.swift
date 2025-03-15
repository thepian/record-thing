//
//  SimpleCameraView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 16.07.23.
//

import SwiftUI

// https://github.com/daved01/LiveCameraSwiftUI/blob/main/LiveCameraSwiftUI/FrameView.swift
public struct SimpleCameraView: View {
    let model: CameraViewModel
    var image: CGImage?
    private let label = Text("Live video frame")
    
    public init(model: CameraViewModel) {
        self.model = model
        self.image = nil
    }
    
    public init(model: CameraViewModel, image: CGImage?) {
        self.model = model
        self.image = image
    }
    
    public var body: some View {
        if let image = image {
            Image(image, scale: 1.0, orientation: .up, label: label)
        } else {
            VStack {
//                Image(model.bgImageSet)
//                    .resizable()
//                    .scaledToFill()
//                    .edgesIgnoringSafeArea(.all)
            }.frame(maxWidth: .infinity, maxHeight: .infinity) // TODO frame(maxWidth: UIScreen.main.bounds.size.width, maxHeight: UIScreen.main.bounds.size.height)
        }
    }
}

struct SimpleCameraView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var model = CameraViewModel()
        
        // Create a preview with the default background image
        let defaultPreview = SimpleCameraView(model: model)
            .previewDisplayName("Default Background")
        
        // Create a preview with the mountain bike image
        let mountainBikeImage = loadCGImage(named: "thepia_a_high-end_electric_mountain_bike_1")
        let mountainBikePreview = SimpleCameraView(model: model, image: mountainBikeImage)
            .previewDisplayName("Mountain Bike")
        
        return Group {
            defaultPreview
            mountainBikePreview
        }
    }
    
    // Helper function to load an image asset as CGImage
    static func loadCGImage(named imageName: String) -> CGImage? {
        // Load the RecordImage from the asset catalog
        guard let recordImage = RecordImage(named: imageName) else {
            print("Failed to load image named: \(imageName)")
            return nil
        }
        
        // Convert RecordImage to CGImage
        #if canImport(UIKit)
        return recordImage.cgImage
        #elseif canImport(AppKit)
        return recordImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }
}
