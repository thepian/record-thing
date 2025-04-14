/*
See LICENSE folder for this sample's licensing information.

Abstract:
Definition of how the ingredients should appear in their thumbnail and card appearances.
*/

import SwiftUI
import RecordLib


// MARK: - SwiftUI

extension Evidence {
    
    /// Defines how the `Evidence`'s title should be displayed in card mode
    public struct CardTitle {
        var color = Color.black
        var rotation = Angle.degrees(0)
        var offset = CGSize.zero
        var blendMode = BlendMode.normal
        var opacity: Double = 1
        var fontSize: Double = 1
        
        public init(
            color: Color = .black,
            rotation: Angle = .degrees(0),
            offset: CGSize = .zero,
            blendMode: BlendMode = .normal,
            opacity: Double = 1,
            fontSize: Double = 1
        ) {
            self.color = color
            self.rotation = rotation
            self.offset = offset
            self.blendMode = blendMode
            self.opacity = opacity
            self.fontSize = fontSize
        }
    }
    
    /// Defines a state for the `Evidence` to transition from when changing between card and thumbnail
    public struct Crop {
        var xOffset: Double = 0
        var yOffset: Double = 0
        var scale: Double = 1
        
        var offset: CGSize {
            CGSize(width: xOffset, height: yOffset)
        }
        
        public init(
            xOffset: Double = 0,
            yOffset: Double = 0,
            scale: Double = 1
        ) {
            self.xOffset = xOffset
            self.yOffset = yOffset
            self.scale = scale
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

extension Evidence {
    static let avocado = Evidence(
        id: "avocado",
        thing_account_id: "acc",
        thing_id: "id123"
//        name: String(localized: "Avocado", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .brown,
//            offset: CGSize(width: 0, height: 20),
//            blendMode: .plusDarker,
//            opacity: 0.4,
//            fontSize: 60
//        )
    )
    
    static let almondMilk = Evidence(
        id: "almond-milk",
        thing_account_id: "acc",
        thing_id: "id1231"
//        name: String(localized: "Almond Milk", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            offset: CGSize(width: 0, height: -140),
//            blendMode: .overlay,
//            fontSize: 40
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1)
    )
    
    static let banana = Evidence(
        id: "banana",
        thing_account_id: "acc",
        thing_id: "id1232"
//        name: String(localized: "Banana", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            rotation: Angle.degrees(-30),
//            offset: CGSize(width: 0, height: 0),
//            blendMode: .overlay,
//            fontSize: 70
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1)
    )
    
    static let blueberry = Evidence(
        id: "blueberry",
        thing_account_id: "acc",
        thing_id: "id1233"
//        name: String(localized: "Blueberry", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .white,
//            offset: CGSize(width: 0, height: 100),
//            opacity: 0.5,
//            fontSize: 45
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 2)
    )
    
    static let carrot = Evidence(
        id: "carrot",
        thing_account_id: "acc",
        thing_id: "id1234"
//        name: String(localized: "Carrot", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            rotation: Angle.degrees(-90),
//            offset: CGSize(width: -120, height: 100),
//            blendMode: .plusDarker,
//            opacity: 0.3,
//            fontSize: 70
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1.2)
    )
    
    static let chocolate = Evidence(
        id: "chocolate",
        thing_account_id: "acc",
        thing_id: "id1235"
//        name: String(localized: "Chocolate", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .brown,
//            rotation: Angle.degrees(-11),
//            offset: CGSize(width: 0, height: 10),
//            blendMode: .plusDarker,
//            opacity: 0.8,
//            fontSize: 45
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1)
    )
    
    static let coconut = Evidence(
        id: "coconut",
        thing_account_id: "acc",
        thing_id: "id1231"
//        name: String(localized: "Coconut", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .brown,
//            offset: CGSize(width: 40, height: 110),
//            blendMode: .plusDarker,
//            opacity: 0.8,
//            fontSize: 36
//        ),
//        thumbnailCrop: Crop(scale: 1.5)
    )
    
    static let kiwi = Evidence(
        id: "kiwi",
        thing_account_id: "acc",
        thing_id: "id1232"
//        name: String(localized: "Kiwi", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            offset: CGSize(width: 0, height: 0),
//            blendMode: .overlay,
//            fontSize: 140
//        ),
//        thumbnailCrop: Crop(scale: 1.1)
    )
    
    static let lemon = Evidence(
        id: "lemon",
        thing_account_id: "acc",
        thing_id: "id1233"
//        name: String(localized: "Lemon", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            rotation: Angle.degrees(-9),
//            offset: CGSize(width: 15, height: 90),
//            blendMode: .overlay,
//            fontSize: 80
//        ),
//        thumbnailCrop: Crop(scale: 1.1)
    )
    
    static let mango = Evidence(
        id: "mango",
        thing_account_id: "acc",
        thing_id: "id1234"
//        name: String(localized: "Mango", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .orange,
//            offset: CGSize(width: 0, height: 20),
//            blendMode: .plusLighter,
//            fontSize: 70
//        )
    )
    
    static let orange = Evidence(
        id: "orange",
        thing_account_id: "acc",
        thing_id: "id1235"
//        name: String(localized: "Orange", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            rotation: Angle.degrees(-90),
//            offset: CGSize(width: -130, height: -60),
//            blendMode: .overlay,
//            fontSize: 80
//        ),
//        thumbnailCrop: Crop(yOffset: -15, scale: 2)
    )
    
    static let papaya = Evidence(
        id: "papaya",
        thing_account_id: "acc",
        thing_id: "id1231"
//        name: String(localized: "Papaya", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            offset: CGSize(width: -20, height: 20),
//            blendMode: .overlay,
//            fontSize: 70
//        ),
//        thumbnailCrop: Crop(scale: 1)
    )
    
    static let peanutButter = Evidence(
        id: "peanut-butter",
        thing_account_id: "acc",
        thing_id: "id1232"
//        name: String(localized: "Peanut Butter", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            offset: CGSize(width: 0, height: 190),
//            blendMode: .overlay,
//            fontSize: 35
//        ),
//        thumbnailCrop: Crop(yOffset: -20, scale: 1.2)
    )
    
    static let pineapple = Evidence(
        id: "pineapple",
        thing_account_id: "acc",
        thing_id: "id1233"
//        name: String(localized: "Pineapple", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .yellow,
//            offset: CGSize(width: 0, height: 90),
//            blendMode: .plusLighter,
//            opacity: 0.5,
//            fontSize: 55
//        )
    )
    
    static let raspberry = Evidence(
        id: "raspberry",
        thing_account_id: "acc",
        thing_id: "id1234"
//        name: String(localized: "Raspberry", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .pink,
//            blendMode: .plusLighter,
//            fontSize: 50
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1.5)
    )
    
    static let spinach = Evidence(
        id: "spinach",
        thing_account_id: "acc",
        thing_id: "id1235"
//        name: String(localized: "Spinach", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            offset: CGSize(width: 0, height: -150),
//            blendMode: .overlay,
//            fontSize: 70
//        ),
//        thumbnailCrop: Crop(yOffset: 0, scale: 1)
    )
    
    static let strawberry = Evidence(
        id: "strawberry",
        thing_account_id: "acc",
        thing_id: "id1231"
//        name: String(localized: "Strawberry", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .white,
//            offset: CGSize(width: 35, height: -5),
//            blendMode: .softLight,
//            opacity: 0.7,
//            fontSize: 30
//        ),
//        thumbnailCrop: Crop(scale: 2.5),
//        cardCrop: Crop(xOffset: -110, scale: 1.35)
    )

    static let water = Evidence(
        id: "water",
        thing_account_id: "acc",
        thing_id: "id1231"
//        name: String(localized: "Water", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            color: .blue,
//            offset: CGSize(width: 0, height: 150),
//            opacity: 0.2,
//            fontSize: 50
//        ),
//        thumbnailCrop: Crop(yOffset: -10, scale: 1.2)
    )
    
    static let watermelon = Evidence(
        id: "watermelon",
        thing_account_id: "acc",
        thing_id: "id1232"
//        name: String(localized: "Watermelon", table: "Evidence", comment: "Evidence name"),
//        title: CardTitle(
//            rotation: Angle.degrees(-50),
//            offset: CGSize(width: -80, height: -50),
//            blendMode: .overlay,
//            fontSize: 25
//        ),
//        thumbnailCrop: Crop(yOffset: -10, scale: 1.2)
    )
}
