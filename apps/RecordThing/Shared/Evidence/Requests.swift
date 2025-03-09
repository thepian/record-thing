//
//  Requests.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 09.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//
import Foundation
import Blackbird

struct Requests: BlackbirdModel, Identifiable {
    static var tableName: String = "requests"
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$id ]

    // Primary key fields
    @BlackbirdColumn var id: String  // KSUID
    @BlackbirdColumn var account_id: String = ""
    
    // Request details
    @BlackbirdColumn var url: String?
    @BlackbirdColumn var status: String?
    @BlackbirdColumn var delivery_method: String?
    @BlackbirdColumn var delivery_target: String?
    
    // Type references
    @BlackbirdColumn var universe_id: Int?
    
    // Timestamps
//    @BlackbirdColumn var created_at: Date
//    @BlackbirdColumn var completed_at: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, url, status, delivery_method, delivery_target, universe_id
    }
    
    // Computed properties
    var title: String {
        get {
            "\(delivery_method ?? "") \(status ?? "") (\(id.prefix(6)))"
        }
    }
    
    var description: String {
        get {
            "\(delivery_method ?? "") \(status ?? "") (\(id.prefix(6)))\n\(url ?? "")"
        }
    }
}

// MARK: - Things List
extension Requests {
    @RequestsArrayBuilder
    static func all(includingPaid: Bool = true) -> [Requests] {
        Requests(id: "id123", account_id: "a", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com")
        Requests(id: "id234", account_id: "a", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com")
    }

    // Used in previews.
    static var Electronics: Requests { Requests(id: "id123", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com") }
    static var Pet: Requests  { Requests(id: "id1234", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com") }
    static var Room: Requests  { Requests(id: "id1235", url: "https://example.com/request/2so4rEgF9EVQPBUrvubUQ6AyDVN", status: "expired", delivery_method: "email", delivery_target: "user0@example.com") }
}


// MARK: - Things Builder
@resultBuilder
enum RequestsArrayBuilder {
    static func buildEither(first component: [Requests]) -> [Requests] {
        return component
    }

    static func buildEither(second component: [Requests]) -> [Requests] {
        return component
    }

    static func buildOptional(_ component: [Requests]?) -> [Requests] {
        return component ?? []
    }

    static func buildExpression(_ expression: Requests) -> [Requests] {
        return [expression]
    }

    static func buildExpression(_ expression: ()) -> [Requests] {
        return []
    }

    static func buildBlock(_ requests: [Requests]...) -> [Requests] {
        return requests.flatMap { $0 }
    }
}
