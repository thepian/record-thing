//
//  Strategists.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird

public struct Strategists: BlackbirdModel, Identifiable {
    public typealias ID = String
    
    static public var tableName: String = "strategists"
    static public var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id, \.$id ]

    // Primary key fields
    @BlackbirdColumn public var id: String  // KSUID
    @BlackbirdColumn public var account_id: String
    
    // Content fields
    @BlackbirdColumn public var title: String?
    @BlackbirdColumn public var description: String?
    @BlackbirdColumn public var tags: String?  // JSON array
    
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

// MARK: - Strategists List
extension Strategists {
    @StrategistsArrayBuilder
    static public func all(includingPaid: Bool = true) -> [Strategists] {
        Strategists(id: "strat123", account_id: "acc")
        Strategists(id: "strat234", account_id: "acc")
    }

    // Used in previews.
    static public var AIStrategy: Strategists {
        Strategists(id: "strat123", account_id: "acc", title: "AI & Machine Learning", description: "Strategic focus on AI technologies")
    }
    static public var BusinessStrategy: Strategists {
        Strategists(id: "strat234", account_id: "acc", title: "Business Development", description: "Growth and expansion strategies")
    }
}

// MARK: - Strategists Builder
@resultBuilder
enum StrategistsArrayBuilder {
    static public func buildEither(first component: [Strategists]) -> [Strategists] {
        return component
    }

    static public func buildEither(second component: [Strategists]) -> [Strategists] {
        return component
    }

    static public func buildOptional(_ component: [Strategists]?) -> [Strategists] {
        return component ?? []
    }

    static public func buildExpression(_ expression: Strategists) -> [Strategists] {
        return [expression]
    }

    static public func buildExpression(_ expression: ()) -> [Strategists] {
        return []
    }

    static public func buildBlock(_ strategists: [Strategists]...) -> [Strategists] {
        return strategists.flatMap { $0 }
    }
}
