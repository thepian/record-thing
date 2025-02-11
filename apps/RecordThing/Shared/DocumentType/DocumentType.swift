//
//  DocumentType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 15.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
import Blackbird

struct DocumentType: BlackbirdModel {
    static var tableName: String = "document_type"
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$lang, \.$rootName, \.$name ]

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
    
    @BlackbirdColumn var lang: String
    @BlackbirdColumn var rootName: String
    @BlackbirdColumn var name: String
    @BlackbirdColumn var url: URL?

    @BlackbirdColumn var canonicalImage: Data?
}


// MARK: - DocumentType List
extension DocumentType {
    @DocumentTypeArrayBuilder
    static func all(includingPaid: Bool = true) -> [DocumentType] {
        DocumentType(lang: "en", rootName: "Document", name: "-")
        DocumentType(lang: "en", rootName: "Receipt", name: "-")
    }

    // Used in previews.
    static var Document: DocumentType { DocumentType(lang: "en", rootName: "Document", name: "-") }
    static var Receipt: DocumentType  { DocumentType(lang: "en", rootName: "Receipt", name: "-") }
    static var Card: DocumentType  { DocumentType(lang: "en", rootName: "Card", name: "-") }
    static var Purchase: DocumentType  { DocumentType(lang: "en", rootName: "Receipt", name: "Purchase") }
    static var Membership: DocumentType  { DocumentType(lang: "en", rootName: "Card", name: "Membership") }
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
