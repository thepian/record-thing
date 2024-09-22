//
//  ProductType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 15.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Blackbird

/*
 TODO fill in database content if empty
 
 Electronics
 Pet
 Room
 Furniture
 Jewelry
 Sports
 Transportation
 
 * Electronics/Camera
 * Electronics/Loudspeaker
 * Electronics/Headphones
 * Pet/Dog
 * Pet/Cat
 * Room/Living Room
 * Room/Bedroom
 * Furniture/Chair
 * Furniture/Table
 * Jewelry/Necklace
 * Jewelry/Wristwatch
 & Jewelry/Pen/Fountain
 * Sports/Shoes/Football
 * Sports/Golf/Clubs
 * Transportation/Car
 * Transportation/Bicycle
 
 */

struct ProductRootType: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$name ]
    
    @BlackbirdColumn var name: String

}

struct ProductType: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$rootName, \.$name ]
    
    var fullName: String {
        get {
            return rootName + "/" + name
        }
    }
    
    var description: String {
        get {
            return "This would be the description!"
        }
    }
    
    @BlackbirdColumn var rootName: String
    @BlackbirdColumn var name: String
    @BlackbirdColumn var url: URL?
    
    // GPC Browser checkup: https://gpc-browser.gs1.org
    @BlackbirdColumn var gpcRoot: String?
    @BlackbirdColumn var gpcName: String?
    
    // UNSPSC product ID https://www.ungm.org/Public/UNSPSC
    @BlackbirdColumn var unspscID: Int?
    
}

enum PublicDataType: Int, BlackbirdIntegerEnum {
    case unknown
    case scannedobjects
}

struct PublicDataPoint: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$url ]
    
    @BlackbirdColumn var url: String
    @BlackbirdColumn var type: PublicDataType
    @BlackbirdColumn var rootName: String
    @BlackbirdColumn var name: String
}

//extension ProductType: Hashable {
//    static func == (lhs: ProductType, rhs: ProductType) -> Bool {
//        lhs.name == rhs.name
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(name)
//    }
//}

// MARK: - ProductType List
extension ProductType {
    @ProductTypeArrayBuilder
    static func all(includingPaid: Bool = true) -> [ProductType] {
        ProductType(rootName: "Electronics", name: "-")
        ProductType(rootName: "Pets", name: "-")
//        ProductType(rootName: "berry-blue", name: String(localized: "Berry Blue", comment: "ProductType name")) {
//            AttributedString(localized: "*Filling* and *refreshing*, this smoothie will fill you with joy!",
//                             comment: "Berry Blue smoothie description")
//
//            Ingredient.orange.measured(with: .cups).scaled(by: 1.5)
//            Ingredient.blueberry.measured(with: .cups)
//            Ingredient.avocado.measured(with: .cups).scaled(by: 0.2)
//        }
//
//        ProductType(id: "carrot-chops", title: String(localized: "Carrot Chops", comment: "ProductType name")) {
//            AttributedString(localized: "*Packed* with vitamin A and C, Carrot Chops is a great way to start your day!",
//                             comment: "Carrot Chops smoothie description")
//
//            Ingredient.orange.measured(with: .cups).scaled(by: 1.5)
//            Ingredient.carrot.measured(with: .cups).scaled(by: 0.5)
//            Ingredient.mango.measured(with: .cups).scaled(by: 0.5)
//        }
//
//
//        ProductType(id: "thats-berry-bananas", title: String(localized: "That's Berry Bananas!", comment: "ProductType name")) {
//            AttributedString(localized: "You'll go *crazy* with this classic!", comment: "That's Berry Bananas! smoothie description")
//
//            Ingredient.almondMilk.measured(with: .cups)
//            Ingredient.banana.measured(with: .cups)
//            Ingredient.strawberry.measured(with: .cups)
//        }
//
    }

    // Used in previews.
    static var Electronics: ProductType { ProductType(rootName: "Electronics", name: "-") }
    static var Pet: ProductType  { ProductType(rootName: "Pet", name: "-") }
    static var Room: ProductType  { ProductType(rootName: "Room", name: "-") }
    static var Furniture: ProductType  { ProductType(rootName: "Furniture", name: "-") }
    static var Jewelry: ProductType  { ProductType(rootName: "Jewelry", name: "-") }
    static var Sports: ProductType  { ProductType(rootName: "Sports", name: "-") }
    static var Transportation: ProductType  { ProductType(rootName: "Transportation", name: "-") }
}

// MARK: - ProductType Builder
@resultBuilder
enum ProductTypeArrayBuilder {
    static func buildEither(first component: [ProductType]) -> [ProductType] {
        return component
    }

    static func buildEither(second component: [ProductType]) -> [ProductType] {
        return component
    }

    static func buildOptional(_ component: [ProductType]?) -> [ProductType] {
        return component ?? []
    }

    static func buildExpression(_ expression: ProductType) -> [ProductType] {
        return [expression]
    }

    static func buildExpression(_ expression: ()) -> [ProductType] {
        return []
    }

    static func buildBlock(_ products: [ProductType]...) -> [ProductType] {
        return products.flatMap { $0 }
    }
}
