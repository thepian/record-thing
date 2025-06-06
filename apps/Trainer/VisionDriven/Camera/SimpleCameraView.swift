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
        // Load the UIImage from the asset catalog
        guard let uiImage = UIImage(named: imageName) else {
            print("Failed to load image named: \(imageName)")
            return nil
        }
        
        // Convert UIImage to CGImage
        return uiImage.cgImage
    }
}
