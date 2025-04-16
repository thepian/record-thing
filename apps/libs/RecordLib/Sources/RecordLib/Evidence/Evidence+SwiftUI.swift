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
        thing_id: "id123",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let almondMilk = Evidence(
        id: "almond-milk",
        thing_account_id: "acc",
        thing_id: "id1231",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let banana = Evidence(
        id: "banana",
        thing_account_id: "acc",
        thing_id: "id1232",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let blueberry = Evidence(
        id: "blueberry",
        thing_account_id: "acc",
        thing_id: "id1233",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let carrot = Evidence(
        id: "carrot",
        thing_account_id: "acc",
        thing_id: "id1234",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let chocolate = Evidence(
        id: "chocolate",
        thing_account_id: "acc",
        thing_id: "id1235",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let coconut = Evidence(
        id: "coconut",
        thing_account_id: "acc",
        thing_id: "id1231",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let kiwi = Evidence(
        id: "kiwi",
        thing_account_id: "acc",
        thing_id: "id1232",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let lemon = Evidence(
        id: "lemon",
        thing_account_id: "acc",
        thing_id: "id1233",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let mango = Evidence(
        id: "mango",
        thing_account_id: "acc",
        thing_id: "id1234",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let orange = Evidence(
        id: "orange",
        thing_account_id: "acc",
        thing_id: "id1235",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let papaya = Evidence(
        id: "papaya",
        thing_account_id: "acc",
        thing_id: "id1231",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let peanutButter = Evidence(
        id: "peanut-butter",
        thing_account_id: "acc",
        thing_id: "id1232",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let pineapple = Evidence(
        id: "pineapple",
        thing_account_id: "acc",
        thing_id: "id1233",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let raspberry = Evidence(
        id: "raspberry",
        thing_account_id: "acc",
        thing_id: "id1234",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let spinach = Evidence(
        id: "spinach",
        thing_account_id: "acc",
        thing_id: "id1235",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let strawberry = Evidence(
        id: "strawberry",
        thing_account_id: "acc",
        thing_id: "id1231",
        created_at: Date.now,
        updated_at: Date.now
    )

    static let water = Evidence(
        id: "water",
        thing_account_id: "acc",
        thing_id: "id1231",
        created_at: Date.now,
        updated_at: Date.now
    )
    
    static let watermelon = Evidence(
        id: "watermelon",
        thing_account_id: "acc",
        thing_id: "id1232",
        created_at: Date.now,
        updated_at: Date.now
    )
}
