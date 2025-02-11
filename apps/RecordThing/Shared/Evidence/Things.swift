//
//  Things.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 03.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird

struct Things: BlackbirdModel, Identifiable {
    static var tableName: String = "things"
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id, \.$id ]

    // Primary key fields
    @BlackbirdColumn var id: String  // KSUID
    @BlackbirdColumn var account_id: String
    
    // Product identifiers
    @BlackbirdColumn var upc: String?  // Universal Product Code
    @BlackbirdColumn var asin: String?  // Amazon Standard Identification Number
    @BlackbirdColumn var elid: String?  // Electronic Product Identifier
    
    // Product details
    @BlackbirdColumn var brand: String?
    @BlackbirdColumn var model: String?
    @BlackbirdColumn var color: String?
    @BlackbirdColumn var tags: String?  // JSON array
    @BlackbirdColumn var category: String?
    
    // Type references
    @BlackbirdColumn var product_type: Int?
    @BlackbirdColumn var document_type: Int?
    
    // Description fields
    @BlackbirdColumn var title: String?
    @BlackbirdColumn var description: String?  // Backing field for description
    
    // Timestamps
//    @BlackbirdColumn var created_at: Date
//    @BlackbirdColumn var updated_at: Date
    
    // Computed property for tags array
    var tagsArray: [String] {
        get {
            guard let tagsString = tags,
                  let data = tagsString.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
    }
}

// MARK: - Things List
extension Things {
    @ThingsArrayBuilder
    static func all(includingPaid: Bool = true) -> [Things] {
        Things(id: "id123", account_id: "acc")
        Things(id: "id234", account_id: "acc")
    }

    // Used in previews.
    static var Electronics: Things { Things(id: "id123", account_id: "acc", title: "Electronics", description: "Electronics description") }
    static var Pet: Things  { Things(id: "id1232", account_id: "acc", title: "Pet", description: "Pet description") }
    static var Room: Things  { Things(id: "id1233", account_id: "acc", title: "Room", description: "Room description") }
    static var Furniture: Things  { Things(id: "id1234", account_id: "acc", title: "Furniture", description: "Furniture description") }
    static var Jewelry: Things  { Things(id: "id1235", account_id: "acc", title: "Jewelry", description: "Jewelry description") }
    static var Sports: Things  { Things(id: "2siiVeL3SRmN4zsoVI1FjBlizix", account_id: "acc", title: "Sports", description: "Sports description") }
    static var Transportation: Things  { Things(id: "id1237", account_id: "acc", title: "Transportation", description: "Transportation description") }
}


// MARK: - Things Builder
@resultBuilder
enum ThingsArrayBuilder {
    static func buildEither(first component: [Things]) -> [Things] {
        return component
    }

    static func buildEither(second component: [Things]) -> [Things] {
        return component
    }

    static func buildOptional(_ component: [Things]?) -> [Things] {
        return component ?? []
    }

    static func buildExpression(_ expression: Things) -> [Things] {
        return [expression]
    }

    static func buildExpression(_ expression: ()) -> [Things] {
        return []
    }

    static func buildBlock(_ things: [Things]...) -> [Things] {
        return things.flatMap { $0 }
    }
}
