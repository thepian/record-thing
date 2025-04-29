//
//  Account.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation
import Blackbird

struct Account: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id ]
    
    @BlackbirdColumn var account_id: String
    @BlackbirdColumn var name: String?
    @BlackbirdColumn var username: String?
    @BlackbirdColumn var email: String?
    @BlackbirdColumn var sms: String?
    @BlackbirdColumn var region: String?
    // password_hash TEXT, -- Optional, for backward compatibility
    @BlackbirdColumn var team_id: String?
    @BlackbirdColumn var is_active: Bool

    @BlackbirdColumn var last_login: Date?
}

struct Owner: BlackbirdModel {
    static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id ]
    
    @BlackbirdColumn var account_id: String
    @BlackbirdColumn var created_at: Date?
}
