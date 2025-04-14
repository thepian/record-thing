//
//  EvidenceType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 15.09.2024.
//  Copyright © 2025 Thepia.. All rights reserved.
//

import Foundation
import Blackbird

public struct EvidenceType: BlackbirdModel, Identifiable {
    static public var tableName: String = "evidence_type"
    static public var primaryKey: [BlackbirdColumnKeyPath] = [ \.$id ]
    
    public var fullName: String {
        get {
            return rootName + "/" + name
        }
    }
    
    public var description: String {
        get {
            return "This would be the description!"
        }
    }
    
    public var group: String {
        get {
            return String(rootName.split(separator: " > ")[0])
        }
    }
    
    @BlackbirdColumn public var id: Int
    @BlackbirdColumn public var lang: String
    @BlackbirdColumn public var rootName: String
    @BlackbirdColumn public var name: String
    @BlackbirdColumn public var url: URL?
    
    // GPC Browser checkup: https://gpc-browser.gs1.org
    @BlackbirdColumn public var gpcRoot: String?
    @BlackbirdColumn public var gpcName: String?
    @BlackbirdColumn public var gpcCode: Int?
    
    // UNSPSC product ID https://www.ungm.org/Public/UNSPSC
    @BlackbirdColumn public var unspscID: Int?
    
    @BlackbirdColumn public var icon_path: String?
}

public enum PublicDataType: Int, BlackbirdIntegerEnum {
    public typealias RawValue = Int
    case unknown
    case scannedobjects
}

public struct PublicDataPoint: BlackbirdModel {
    static public var primaryKey: [BlackbirdColumnKeyPath] = [ \.$url ]
    
    @BlackbirdColumn public var url: String
    @BlackbirdColumn public var type: PublicDataType
    @BlackbirdColumn public var rootName: String
    @BlackbirdColumn public var name: String
}

public struct TestCustomDecoder: BlackbirdModel {
    static public var tableName: String = "test_custom_decoder"
    
    @BlackbirdColumn public var id: Int
    @BlackbirdColumn public var name: String
    @BlackbirdColumn public var thumbnail: URL

    public enum CodingKeys: String, BlackbirdCodingKey {
        case id = "idStr"
        case name = "nameStr"
        case thumbnail = "thumbStr"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Special-case handling for BlackbirdDefaultsDecoder:
        //  supplies a valid numeric string instead of failing on
        //  the empty string ("") returned by BlackbirdDefaultsDecoder
        
        if decoder is BlackbirdDefaultsDecoder {
            self.id = 0
        } else {
            let idStr = try container.decode(String.self, forKey: .id)
            guard let id = Int(idStr) else {
                throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Expected numeric string")
            }
            self.id = id
        }

        self.name = try container.decode(String.self, forKey: .name)
        self.thumbnail = try container.decode(URL.self, forKey: .thumbnail)
    }
}


// MARK: - EvidenceType List
extension EvidenceType {
    @EvidenceTypeArrayBuilder
    static public func all(includingPaid: Bool = true) -> [EvidenceType] {
        EvidenceType(id: 1, lang: "en", rootName: "Electronics", name: "-")
        EvidenceType(id:2, lang: "en", rootName: "Pets", name: "-")
    }

    // Used in previews.
    static public var Electronics: EvidenceType { EvidenceType(id:1, lang: "en", rootName: "-", name: "Electronics") }
    static public var Pet: EvidenceType  { EvidenceType(id:2, lang: "en", rootName: "-", name: "Pet") }
    static public var Room: EvidenceType  { EvidenceType(id:3, lang: "en", rootName: "-", name: "Room") }
    static public var Furniture: EvidenceType  { EvidenceType(id:4, lang: "en", rootName: "-", name: "Furniture") }
    static public var Jewelry: EvidenceType  { EvidenceType(id:5, lang: "en", rootName: "-", name: "Jewelry") }
    static public var Sports: EvidenceType  { EvidenceType(id:6, lang: "en", rootName: "-", name: "Sports") }
    static public var Transportation: EvidenceType  { EvidenceType(id:7, lang: "en", rootName: "-", name: "Transportation") }
}

// MARK: - EvidenceType Builder
@resultBuilder
public enum EvidenceTypeArrayBuilder {
    static public func buildEither(first component: [EvidenceType]) -> [EvidenceType] {
        return component
    }

    static public func buildEither(second component: [EvidenceType]) -> [EvidenceType] {
        return component
    }

    static public func buildOptional(_ component: [EvidenceType]?) -> [EvidenceType] {
        return component ?? []
    }

    static public func buildExpression(_ expression: EvidenceType) -> [EvidenceType] {
        return [expression]
    }

    static public func buildExpression(_ expression: ()) -> [EvidenceType] {
        return []
    }

    static public func buildBlock(_ products: [EvidenceType]...) -> [EvidenceType] {
        return products.flatMap { $0 }
    }
}
