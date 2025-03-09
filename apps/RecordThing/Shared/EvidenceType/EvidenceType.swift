//
//  EvidenceType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 15.09.2024.
//  Copyright © 2025 Thepia.. All rights reserved.
//

import Foundation
import Blackbird

struct EvidenceType: BlackbirdModel, Identifiable {
    static var tableName: String = "evidence_type"
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$id ]
    
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
    
    var group: String {
        get {
            return String(rootName.split(separator: " > ")[0])
        }
    }
    
    @BlackbirdColumn var id: Int
    @BlackbirdColumn var lang: String
    @BlackbirdColumn var rootName: String
    @BlackbirdColumn var name: String
    @BlackbirdColumn var url: URL?
    
    // GPC Browser checkup: https://gpc-browser.gs1.org
    @BlackbirdColumn var gpcRoot: String?
    @BlackbirdColumn var gpcName: String?
    @BlackbirdColumn var gpcCode: Int?
    
    // UNSPSC product ID https://www.ungm.org/Public/UNSPSC
    @BlackbirdColumn var unspscID: Int?
    
    @BlackbirdColumn var icon_path: String?
}

enum PublicDataType: Int, BlackbirdIntegerEnum {
    typealias RawValue = Int
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

struct TestCustomDecoder: BlackbirdModel {
    static var tableName: String = "test_custom_decoder"
    
    @BlackbirdColumn var id: Int
    @BlackbirdColumn var name: String
    @BlackbirdColumn var thumbnail: URL

    enum CodingKeys: String, BlackbirdCodingKey {
        case id = "idStr"
        case name = "nameStr"
        case thumbnail = "thumbStr"
    }

    init(from decoder: Decoder) throws {
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
    static func all(includingPaid: Bool = true) -> [EvidenceType] {
        EvidenceType(id: 1, lang: "en", rootName: "Electronics", name: "-")
        EvidenceType(id:2, lang: "en", rootName: "Pets", name: "-")
    }

    // Used in previews.
    static var Electronics: EvidenceType { EvidenceType(id:1, lang: "en", rootName: "-", name: "Electronics") }
    static var Pet: EvidenceType  { EvidenceType(id:2, lang: "en", rootName: "-", name: "Pet") }
    static var Room: EvidenceType  { EvidenceType(id:3, lang: "en", rootName: "-", name: "Room") }
    static var Furniture: EvidenceType  { EvidenceType(id:4, lang: "en", rootName: "-", name: "Furniture") }
    static var Jewelry: EvidenceType  { EvidenceType(id:5, lang: "en", rootName: "-", name: "Jewelry") }
    static var Sports: EvidenceType  { EvidenceType(id:6, lang: "en", rootName: "-", name: "Sports") }
    static var Transportation: EvidenceType  { EvidenceType(id:7, lang: "en", rootName: "-", name: "Transportation") }
}

// MARK: - EvidenceType Builder
@resultBuilder
enum EvidenceTypeArrayBuilder {
    static func buildEither(first component: [EvidenceType]) -> [EvidenceType] {
        return component
    }

    static func buildEither(second component: [EvidenceType]) -> [EvidenceType] {
        return component
    }

    static func buildOptional(_ component: [EvidenceType]?) -> [EvidenceType] {
        return component ?? []
    }

    static func buildExpression(_ expression: EvidenceType) -> [EvidenceType] {
        return [expression]
    }

    static func buildExpression(_ expression: ()) -> [EvidenceType] {
        return []
    }

    static func buildBlock(_ products: [EvidenceType]...) -> [EvidenceType] {
        return products.flatMap { $0 }
    }
}
