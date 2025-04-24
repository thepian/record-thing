//
//  Requests.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 09.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//
import Foundation
import Blackbird

public struct Requests: BlackbirdModel, Identifiable {
    public typealias ID = String
    
    static public var tableName: String = "requests"
    static public var primaryKey: [BlackbirdColumnKeyPath] = [ \.$id ]

    // Primary key fields
    @BlackbirdColumn public var id: String  // KSUID
    @BlackbirdColumn public var account_id: String = ""
    
    // Request details
    @BlackbirdColumn public var url: String?
    @BlackbirdColumn public var status: String?
    @BlackbirdColumn public var delivery_method: String?
    @BlackbirdColumn public var delivery_target: String?
    
    // Type references
    @BlackbirdColumn public var universe_id: Int?
    
    // Timestamps
//    @BlackbirdColumn public var created_at: Date
//    @BlackbirdColumn public var completed_at: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, url, status, delivery_method, delivery_target, universe_id
    }
    
    // Computed properties
    public var title: String {
        get {
            "\(delivery_method ?? "") \(status ?? "") (\(id.prefix(6)))"
        }
    }
    
    public var description: String {
        get {
            "\(delivery_method ?? "") \(status ?? "") (\(id.prefix(6)))\n\(url ?? "")"
        }
    }
}

// MARK: - Things List
extension Requests {
    @RequestsArrayBuilder
    static public func all(includingPaid: Bool = true) -> [Requests] {
        Requests(id: "id123", account_id: "a", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com")
        Requests(id: "id234", account_id: "a", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com")
    }

    // Used in previews.
    static public var Electronics: Requests { Requests(id: "id123", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com") }
    static public var Pet: Requests  { Requests(id: "id1234", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com") }
    static public var Room: Requests  { Requests(id: "id1235", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com") }
}


// MARK: - Things Builder
@resultBuilder
enum RequestsArrayBuilder {
    static public func buildEither(first component: [Requests]) -> [Requests] {
        return component
    }

    static public func buildEither(second component: [Requests]) -> [Requests] {
        return component
    }

    static public func buildOptional(_ component: [Requests]?) -> [Requests] {
        return component ?? []
    }

    static public func buildExpression(_ expression: Requests) -> [Requests] {
        return [expression]
    }

    static public func buildExpression(_ expression: ()) -> [Requests] {
        return []
    }

    static public func buildBlock(_ requests: [Requests]...) -> [Requests] {
        return requests.flatMap { $0 }
    }
}
