import Blackbird
import Foundation

public struct FlowsUser: BlackbirdModel {
    public static var primaryKey: [BlackbirdColumnKeyPath] = [\.$userId]
    
    @BlackbirdColumn public var userId: String
    @BlackbirdColumn public var email: String
    @BlackbirdColumn public var name: String?
    @BlackbirdColumn public var avatar: String?
    @BlackbirdColumn public var emailVerified: Bool
    @BlackbirdColumn public var createdAt: String?
    @BlackbirdColumn public var lastLoginAt: String?
    @BlackbirdColumn public var metadata: String? // JSON string
    @BlackbirdColumn public var authMethod: String?
    @BlackbirdColumn public var lastUsed: String
    
    public init(
        userId: String,
        email: String,
        name: String? = nil,
        avatar: String? = nil,
        emailVerified: Bool,
        createdAt: String? = nil,
        lastLoginAt: String? = nil,
        metadata: String? = nil,
        authMethod: String? = nil,
        lastUsed: String
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.avatar = avatar
        self.emailVerified = emailVerified
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.metadata = metadata
        self.authMethod = authMethod
        self.lastUsed = lastUsed
    }
}

public struct FlowsAuthSession: BlackbirdModel {
    public static var primaryKey: [BlackbirdColumnKeyPath] = [\.$userId]
    
    @BlackbirdColumn public var userId: String
    @BlackbirdColumn public var email: String
    @BlackbirdColumn public var accessToken: String
    @BlackbirdColumn public var refreshToken: String?
    @BlackbirdColumn public var expiresAt: Double
    @BlackbirdColumn public var refreshedAt: Double?
    @BlackbirdColumn public var authMethod: String?
    @BlackbirdColumn public var supabaseToken: String?
    @BlackbirdColumn public var supabaseExpiresAt: Double?
    @BlackbirdColumn public var savedAt: String
    
    public init(
        userId: String,
        email: String,
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Double,
        refreshedAt: Double? = nil,
        authMethod: String? = nil,
        supabaseToken: String? = nil,
        supabaseExpiresAt: Double? = nil,
        savedAt: String
    ) {
        self.userId = userId
        self.email = email
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.refreshedAt = refreshedAt
        self.authMethod = authMethod
        self.supabaseToken = supabaseToken
        self.supabaseExpiresAt = supabaseExpiresAt
        self.savedAt = savedAt
    }
}

