//
//  Things.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 03.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird

public struct Things: BlackbirdModel, Identifiable {
    static public var tableName: String = "things"
    static public var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id, \.$id ]

    // Primary key fields
    @BlackbirdColumn public var id: String  // KSUID
    @BlackbirdColumn public var account_id: String
    
    // Product identifiers
    @BlackbirdColumn public var upc: String?  // Universal Product Code
    @BlackbirdColumn public var asin: String?  // Amazon Standard Identification Number
    @BlackbirdColumn public var elid: String?  // Electronic Product Identifier
    
    // Product details
    @BlackbirdColumn public var brand: String?
    @BlackbirdColumn public var model: String?
    @BlackbirdColumn public var color: String?
    @BlackbirdColumn public var tags: String?  // JSON array
    @BlackbirdColumn public var category: String?
    
    // Type references
    @BlackbirdColumn public var evidence_type: String?
    @BlackbirdColumn public var evidence_type_name: String?
    
    // Description fields
    @BlackbirdColumn public var title: String?
    @BlackbirdColumn public var description: String?  // Backing field for description
    
    // Timestamps
    @BlackbirdColumn public var created_at: Date?
    @BlackbirdColumn public var updated_at: Date?
    
    // Computed property for tags array
    public var tagsArray: [String] {
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
    static public func all(includingPaid: Bool = true) -> [Things] {
        Things(id: "id123", account_id: "acc")
        Things(id: "id234", account_id: "acc")
    }

    // Used in previews.
    static public var Electronics: Things { Things(id: "id123", account_id: "acc", title: "Electronics", description: "Electronics description") }
    static public var Pet: Things  { Things(id: "id1232", account_id: "acc", title: "Pet", description: "Pet description") }
    static public var Room: Things  { Things(id: "id1233", account_id: "acc", title: "Room", description: "Room description") }
    static public var Furniture: Things  { Things(id: "id1234", account_id: "acc", title: "Furniture", description: "Furniture description") }
    static public var Jewelry: Things  { Things(id: "id1235", account_id: "acc", title: "Jewelry", description: "Jewelry description") }
    static public var Sports: Things  { Things(id: "2siiVeL3SRmN4zsoVI1FjBlizix", account_id: "acc", title: "Sports", description: "Sports description") }
    static public var Transportation: Things  { Things(id: "id1237", account_id: "acc", title: "Transportation", description: "Transportation description") }
}


// MARK: - Things Builder
@resultBuilder
enum ThingsArrayBuilder {
    static public func buildEither(first component: [Things]) -> [Things] {
        return component
    }

    static public func buildEither(second component: [Things]) -> [Things] {
        return component
    }

    static public func buildOptional(_ component: [Things]?) -> [Things] {
        return component ?? []
    }

    static public func buildExpression(_ expression: Things) -> [Things] {
        return [expression]
    }

    static public func buildExpression(_ expression: ()) -> [Things] {
        return []
    }

    static public func buildBlock(_ things: [Things]...) -> [Things] {
        return things.flatMap { $0 }
    }
}
