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
    @BlackbirdColumn var name: String
    @BlackbirdColumn var url: URL?

}
