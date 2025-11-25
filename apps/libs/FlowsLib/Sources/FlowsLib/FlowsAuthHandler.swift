import Foundation

/// Protocol for handling authentication persistence and operations
/// Implementations should handle storage (e.g. SQLite, Keychain)
public protocol FlowsAuthHandler {
    func saveSession(_ session: [String: Any]) async throws
    func getSession() async throws -> [String: Any]?
    func clearSession() async throws
    
    func saveUser(_ user: [String: Any]) async throws
    func getUser(_ userId: String) async throws -> [String: Any]?
    func clearUser(_ userId: String) async throws
    
    func updateUserMetadata(userId: String, metadata: [String: Any]) async throws
    func patchMetadata(userId: String, patch: [String: Any], appCode: String, token: String) async throws -> [String: Any]
}
