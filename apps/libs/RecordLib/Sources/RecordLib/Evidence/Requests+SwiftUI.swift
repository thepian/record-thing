/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Definition of how the ingredients should appear in their thumbnail and card appearances.
*/

import SwiftUI

// MARK: - SwiftUI

extension Requests {
    
    /// Defines how the `Evidence`'s title should be displayed in card mode
    public struct CardTitle {
        var color = Color.black
        var rotation = Angle.degrees(0)
        var offset = CGSize.zero
        var blendMode = BlendMode.normal
        var opacity: Double = 1
        var fontSize: Double = 1
    }
    
    /// Defines a state for the `Evidence` to transition from when changing between card and thumbnail
    struct Crop {
        var xOffset: Double = 0
        var yOffset: Double = 0
        var scale: Double = 1
        
        var offset: CGSize {
            CGSize(width: xOffset, height: yOffset)
        }
    }
    
    /// The `Evidence`'s image, useful for backgrounds or thumbnails
    public var image: Image {
        Image("product/Room", label: Text("<title>"))
            .renderingMode(.original)

//        Image("evidence/\(id)", label: Text(name))
//            .renderingMode(.original)
//        Image("product/\(rootName)", label: Text(name))
//            .renderingMode(.original)
    }
}

// MARK: - All Evidence

extension Requests {
    static let avocado = Requests(
        id: "avocado",
        url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN",
        status: "expired"
//        name: String(localized: "Avocado", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .brown,
//            offset: CGSize(width: 0, height: 20),
//            blendMode: .plusDarker,
//            opacity: 0.4,
//            fontSize: 60
//        )
    )
    
    static let almondMilk = Requests(
        id: "almond-milk",
        url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN",
        status: "expired"
//        name: String(localized: "Almond Milk", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            offset: CGSize(width: 0, height: -140),
//            blendMode: .overlay,
//            fontSize: 40
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1)
    )
    
    static let banana = Requests(
        id: "banana",
        url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN",
        status: "expired"
//        name: String(localized: "Banana", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            rotation: Angle.degrees(-30),
//            offset: CGSize(width: 0, height: 0),
//            blendMode: .overlay,
//            fontSize: 70
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1)
    )
}
