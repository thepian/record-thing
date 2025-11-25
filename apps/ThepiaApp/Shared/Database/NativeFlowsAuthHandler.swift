import Foundation
import FlowsLib
import RecordLib
import Blackbird
import os

public class NativeFlowsAuthHandler: FlowsAuthHandler {
    private var db: Blackbird.Database? {
        return AppDatasource.shared.db
    }
    
    private let logger = Logger(subsystem: "com.record-thing", category: "auth")
    
    public init() {}
    
    public func saveSession(_ session: [String: Any]) async throws {
        guard let db = db else { 
            logger.error("saveSession: Database not initialized")
            throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) 
        }
        
        // Extract fields
        guard let userId = session["userId"] as? String,
              let email = session["email"] as? String,
              let accessToken = session["accessToken"] as? String,
              let expiresAt = session["expiresAt"] as? Double,
              let savedAt = session["savedAt"] as? String else {
            throw NSError(domain: "NativeFlowsAuthHandler", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required session fields"])
        }
        
        let authSession = FlowsAuthSession(
            userId: userId,
            email: email,
            accessToken: accessToken,
            refreshToken: session["refreshToken"] as? String,
            expiresAt: expiresAt,
            refreshedAt: session["refreshedAt"] as? Double,
            authMethod: session["authMethod"] as? String,
            supabaseToken: session["supabaseToken"] as? String,
            supabaseExpiresAt: session["supabaseExpiresAt"] as? Double,
            savedAt: savedAt
        )
        
        try await authSession.write(to: db)
        logger.info("Saved session for user: \(userId, privacy: .public)")
        
        // Also update user's lastUsed if user data is present in session (implied by plan)
        // Or just ensure user exists? The plan says "Update users table - persistent profile"
        // We'll assume saveUser is called separately or we extract what we can.
        // For now, just save the session.
    }
    
    public func getSession() async throws -> [String: Any]? {
        guard let db = db else { throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) }
        
        // Get most recent session
        // Blackbird doesn't support complex ordering in `read` easily without raw query or fetching all.
        // Let's fetch all and sort in memory for now (assuming few sessions per device).
        let sessions = try await FlowsAuthSession.read(from: db)
        
        guard let session = sessions.sorted(by: { $0.savedAt > $1.savedAt }).first else {
            logger.debug("getSession: No session found")
            return nil
        }
        
        logger.debug("getSession: Found session for user: \(session.userId, privacy: .public)")
        
        var dict: [String: Any] = [
            "userId": session.userId,
            "email": session.email,
            "accessToken": session.accessToken,
            "expiresAt": session.expiresAt,
            "savedAt": session.savedAt
        ]
        
        if let v = session.refreshToken { dict["refreshToken"] = v }
        if let v = session.refreshedAt { dict["refreshedAt"] = v }
        if let v = session.authMethod { dict["authMethod"] = v }
        if let v = session.supabaseToken { dict["supabaseToken"] = v }
        if let v = session.supabaseExpiresAt { dict["supabaseExpiresAt"] = v }
        
        return dict
    }
    
    public func clearSession() async throws {
        guard let db = db else { throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) }
        
        // Delete all sessions
        // Blackbird doesn't have "deleteAll" on model?
        // Use raw query
        // Use raw query
        try await db.execute("DELETE FROM FlowsAuthSession")
        logger.info("Cleared all sessions")
    }
    
    public func saveUser(_ user: [String: Any]) async throws {
        guard let db = db else { throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) }
        
        guard let userId = user["userId"] as? String,
              let email = user["email"] as? String,
              let emailVerified = user["emailVerified"] as? Bool,
              let lastUsed = user["lastUsed"] as? String else {
             throw NSError(domain: "NativeFlowsAuthHandler", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required user fields"])
        }
        
        var metadataString: String? = nil
        if let metadata = user["metadata"] as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: metadata, options: []),
           let str = String(data: data, encoding: .utf8) {
            metadataString = str
        }
        
        let flowsUser = FlowsUser(
            userId: userId,
            email: email,
            name: user["name"] as? String,
            avatar: user["avatar"] as? String,
            emailVerified: emailVerified,
            createdAt: user["createdAt"] as? String,
            lastLoginAt: user["lastLoginAt"] as? String,
            metadata: metadataString,
            authMethod: user["authMethod"] as? String,
            lastUsed: lastUsed
        )
        
        try await flowsUser.write(to: db)
        logger.info("Saved user: \(userId, privacy: .public)")
    }
    
    public func getUser(_ userId: String) async throws -> [String: Any]? {
        guard let db = db else { throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) }
        
        guard let user = try await FlowsUser.read(from: db, id: userId) else {
            logger.debug("getUser: User not found: \(userId, privacy: .public)")
            return nil
        }
        
        logger.debug("getUser: Found user: \(userId, privacy: .public)")
        
        var dict: [String: Any] = [
            "userId": user.userId,
            "email": user.email,
            "emailVerified": user.emailVerified,
            "lastUsed": user.lastUsed
        ]
        
        if let v = user.name { dict["name"] = v }
        if let v = user.avatar { dict["avatar"] = v }
        if let v = user.createdAt { dict["createdAt"] = v }
        if let v = user.lastLoginAt { dict["lastLoginAt"] = v }
        if let v = user.authMethod { dict["authMethod"] = v }
        
        if let metaStr = user.metadata,
           let data = metaStr.data(using: .utf8),
           let metaDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            dict["metadata"] = metaDict
        }
        
        return dict
    }
    
    public func clearUser(_ userId: String) async throws {
        guard let db = db else { throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) }
        
        // Read the user first, then delete
        guard let user = try await FlowsUser.read(from: db, id: userId) else {
            return // User doesn't exist, nothing to delete
        }
        
        try await user.delete(from: db)
        logger.info("Cleared user: \(userId, privacy: .public)")
    }
    
    public func updateUserMetadata(userId: String, metadata: [String: Any]) async throws {
        guard let db = db else { throw NSError(domain: "NativeFlowsAuthHandler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not initialized"]) }
        
        guard var user = try await FlowsUser.read(from: db, id: userId) else {
            return // User not found, ignore
        }
        
        // Merge metadata
        var currentMetadata: [String: Any] = [:]
        if let metaStr = user.metadata,
           let data = metaStr.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            currentMetadata = dict
        }
        
        // Merge new into current
        for (k, v) in metadata {
            currentMetadata[k] = v
        }
        
        // Serialize back
        if let data = try? JSONSerialization.data(withJSONObject: currentMetadata, options: []),
           let str = String(data: data, encoding: .utf8) {
            user.metadata = str
        }
        
        user.lastUsed = ISO8601DateFormatter().string(from: Date())
        
        try await user.write(to: db)
        logger.info("Updated metadata for user: \(userId, privacy: .public)")
    }
    
    public func patchMetadata(userId: String, patch: [String: Any], appCode: String, token: String) async throws -> [String: Any] {
        // TODO: Implement actual API call
        // For now, just apply the patch locally and return it, mimicking success
        // In a real implementation, we would call the API, get the result, and then update DB.
        
        // In a real implementation, we would call the API, get the result, and then update DB.
        
        logger.info("Patching metadata for user: \(userId, privacy: .public)")
        try await updateUserMetadata(userId: userId, metadata: patch)
        return patch
    }
}
