//
//  Account.swift
//  RecordLib
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
import Blackbird

// MARK: - Account Model

public struct Account: BlackbirdModel {
    public static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id ]
    
    @BlackbirdColumn public var account_id: String
    @BlackbirdColumn public var name: String?
    @BlackbirdColumn public var username: String?
    @BlackbirdColumn public var email: String?
    @BlackbirdColumn public var sms: String?
    @BlackbirdColumn public var region: String?
    // password_hash TEXT, -- Optional, for backward compatibility
    @BlackbirdColumn public var team_id: String?
    @BlackbirdColumn public var is_active: Bool
    @BlackbirdColumn public var last_login: Date?
    
    public init(
        account_id: String,
        name: String? = nil,
        username: String? = nil,
        email: String? = nil,
        sms: String? = nil,
        region: String? = nil,
        team_id: String? = nil,
        is_active: Bool = true,
        last_login: Date? = nil
    ) {
        self.account_id = account_id
        self.name = name
        self.username = username
        self.email = email
        self.sms = sms
        self.region = region
        self.team_id = team_id
        self.is_active = is_active
        self.last_login = last_login
    }
}

// MARK: - Owner Model

public struct Owner: BlackbirdModel {
    public static var primaryKey: [BlackbirdColumnKeyPath] = [ \.$account_id ]
    
    @BlackbirdColumn public var account_id: String
    @BlackbirdColumn public var created_at: Date?
    
    public init(account_id: String, created_at: Date? = nil) {
        self.account_id = account_id
        self.created_at = created_at
    }
}

// MARK: - AccountModel (for app-specific logic)

public struct AccountModel {
    public var pointsSpent = 0
    public var unstampedPoints = 0
    
    public init(pointsSpent: Int = 0, unstampedPoints: Int = 0) {
        self.pointsSpent = pointsSpent
        self.unstampedPoints = unstampedPoints
    }
    
    public mutating func clearUnstampedPoints() {
        unstampedPoints = 0
    }
}

// MARK: - Account Extensions

extension Account {
    /// Check if the account is valid and active
    public var isValid: Bool {
        return !account_id.isEmpty && is_active
    }
    
    /// Get display name for the account
    public var displayName: String {
        return name ?? username ?? email ?? "Unknown User"
    }
    
    /// Check if account has contact information
    public var hasContactInfo: Bool {
        return email != nil || sms != nil
    }
    
    /// Get primary contact method
    public var primaryContact: String? {
        return email ?? sms
    }
}

extension Owner {
    /// Check if owner was created recently (within last 30 days)
    public var isRecentlyCreated: Bool {
        guard let created_at = created_at else { return false }
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        return created_at > thirtyDaysAgo
    }
}
