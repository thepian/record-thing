//
//  Evidence.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 03.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird

struct Evidence: BlackbirdModel, Identifiable {
    static func == (lhs: Evidence, rhs: Evidence) -> Bool {
        lhs.id == rhs.id && lhs.thing_account_id == rhs.thing_account_id
    }
    
    static var tableName: String = "evidence"

    // Primary key fields
    @BlackbirdColumn var id: String  // KSUID
    @BlackbirdColumn var thing_account_id: String
    @BlackbirdColumn var thing_id: String?
    @BlackbirdColumn var request_id: String?
    
//    -- created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    // Type references
    @BlackbirdColumn var evidence_type: Int?

    // Product identifiers
//    @BlackbirdColumn var upc: String?  // Universal Product Code
//    @BlackbirdColumn var asin: String?  // Amazon Standard Identification Number
//    @BlackbirdColumn var elid: String?  // Electronic Product Identifier
    
    // Product details
    @BlackbirdColumn var data: String?
    @BlackbirdColumn var local_file: String?
    
//    var title: CardTitle = {
//        get {
//            return CardTitle()
//        }
//    }
    
//    var thumbnailCrop = Crop()
//    var cardCrop = Crop()

//    enum CodingKeys: String, CodingKey {
//        case id
//        case name
//    }

    var name: String = {
        "Sample name"
    }()
    
    // Timestamps
//    @BlackbirdColumn var created_at: Date
//    @BlackbirdColumn var updated_at: Date
}

// MARK: - All Evidence types

extension Evidence {
    static let all: [Evidence] = [
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
    
    init?(for id: Evidence.ID) {
        guard let result = Evidence.all.first(where: { $0.id == id }) else {
            return nil
        }
        self = result
    }
}
