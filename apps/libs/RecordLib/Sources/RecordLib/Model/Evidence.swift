//
//  Evidence.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 03.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird

public struct Evidence: BlackbirdModel, Identifiable {
    public typealias ID = String
    
    static public func == (lhs: Evidence, rhs: Evidence) -> Bool {
        lhs.id == rhs.id && lhs.thing_account_id == rhs.thing_account_id
    }
    
    static public var tableName: String = "evidence"

    // Primary key fields
    @BlackbirdColumn public var id: String  // KSUID
    @BlackbirdColumn public var thing_account_id: String
    @BlackbirdColumn public var thing_id: String?
    @BlackbirdColumn public var request_id: String?
    @BlackbirdColumn public var strategist_account_id: String?
    @BlackbirdColumn public var strategist_id: String?
    
//    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    // Type references
    @BlackbirdColumn public var evidence_type: Int?

    // Product identifiers
//    @BlackbirdColumn public var upc: String?  // Universal Product Code
//    @BlackbirdColumn public var asin: String?  // Amazon Standard Identification Number
//    @BlackbirdColumn public var elid: String?  // Electronic Product Identifier
    
    // Product details
    @BlackbirdColumn public var data: String?
    @BlackbirdColumn public var local_file: String?
    
//    public var title: CardTitle = {
//        get {
//            return CardTitle()
//        }
//    }
    
//    public var thumbnailCrop = Crop()
//    public var cardCrop = Crop()

//    enum CodingKeys: String, CodingKey {
//        case id
//        case name
//    }

    public var name: String = {
        "Sample name"
    }()
    
    // Timestamps
    @BlackbirdColumn public var created_at: Date
    @BlackbirdColumn public var updated_at: Date
}

// MARK: - All Evidence types

extension Evidence {
    static public let all: [Evidence] = [
        .avocado,
        .almondMilk,
        .banana,
        .blueberry,
        .carrot,
        .chocolate,
        .coconut,
        .kiwi,
        .lemon,
        .mango,
        .orange,
        .papaya,
        .peanutButter,
        .pineapple,
        .raspberry,
        .spinach,
        .strawberry,
        .watermelon
    ]
    
    public init?(for id: Evidence.ID) {
        guard let result = Evidence.all.first(where: { $0.id == id }) else {
            return nil
        }
        self = result
    }
}
