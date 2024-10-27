//
//  DocumentType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 15.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Blackbird

/*
 * Document
 * Receipt
 * Card
 
 * Purchase
 * Contract
 * Insurance
 * Warranty
 * Payment
 * Gift Card
 * Membership Card
 * ID Card
 
 */
struct DocumentType: BlackbirdModel {
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

}


// MARK: - DocumentType List
extension DocumentType {
    @DocumentTypeArrayBuilder
    static func all(includingPaid: Bool = true) -> [DocumentType] {
        DocumentType(rootName: "Document", name: "-")
        DocumentType(rootName: "Receipt", name: "-")
    }

    // Used in previews.
    static var Document: DocumentType { DocumentType(rootName: "Document", name: "-") }
    static var Receipt: DocumentType  { DocumentType(rootName: "Receipt", name: "-") }
    static var Card: DocumentType  { DocumentType(rootName: "Card", name: "-") }
    static var Purchase: DocumentType  { DocumentType(rootName: "Receipt", name: "Purchase") }
    static var Membership: DocumentType  { DocumentType(rootName: "Card", name: "Membership") }
}



// MARK: - ProductType Builder
@resultBuilder
enum DocumentTypeArrayBuilder {
    static func buildEither(first component: [DocumentType]) -> [DocumentType] {
        return component
    }

    static func buildEither(second component: [DocumentType]) -> [DocumentType] {
        return component
    }

    static func buildOptional(_ component: [DocumentType]?) -> [DocumentType] {
        return component ?? []
    }

    static func buildExpression(_ expression: DocumentType) -> [DocumentType] {
        return [expression]
    }

    static func buildExpression(_ expression: ()) -> [DocumentType] {
        return []
    }

    static func buildBlock(_ documents: [DocumentType]...) -> [DocumentType] {
        return documents.flatMap { $0 }
    }
}
