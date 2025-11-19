//
//  DatabaseConnectivityManager.swift
//  RecordLib
//
//  Created by AI Assistant on 08.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Blackbird
import Foundation
import os

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

/// Comprehensive database connectivity manager for macOS with sandbox awareness
public class DatabaseConnectivityManager: ObservableObject {

  // MARK: - Types

  public enum DatabaseMode {
    case production  // App Support folder
    case development  // Git-tracked database
    case debug  // Desktop debug database
    case inMemory  // In-memory clone of bundled database
    case bundled  // Direct access to bundled database (read-only)

    public var displayName: String {
      switch self {
      case .production: return "Production"
      case .development: return "Development"
      case .debug: return "Debug"
      case .inMemory: return "In-Memory"
      case .bundled: return "Bundled"
      }
    }
  }

  public enum ConnectivityIssue {
    case sandboxPermissions
    case fileNotFound
    case quarantineAttributes
    case journalFileBlocked
    case diskSpace
    case corruptedDatabase
    case unknownError(Error)

    var description: String {
      switch self {
      case .sandboxPermissions:
        return "App Sandbox prevents database access"
      case .fileNotFound:
        return "Database file not found at expected location"
      case .quarantineAttributes:
        return "Quarantine attributes prevent database access"
      case .journalFileBlocked:
        return "SQLite journal files cannot be created"
      case .diskSpace:
        return "Insufficient disk space for database operations"
      case .corruptedDatabase:
        return "Database file appears to be corrupted"
      case .unknownError(let error):
        return "Unknown error: \(error.localizedDescription)"
      }
    }

    var recommendation: String {
      switch self {
      case .sandboxPermissions:
        return "Ensure database is in App Support folder within sandbox container"
      case .fileNotFound:
        return "Check if database file exists and is accessible"
      case .quarantineAttributes:
        return "Remove quarantine attributes from bundled database"
      case .journalFileBlocked:
        return "Verify write permissions in database directory"
      case .diskSpace:
        return "Free up disk space and try again"
      case .corruptedDatabase:
        return "Reset database or restore from backup"
      case .unknownError:
        return "Check logs for detailed error information"
      }
    }
  }

  public struct DatabaseDiagnostics {
    public let mode: DatabaseMode
    public let path: String
    public let exists: Bool
    public let isReadable: Bool
    public let isWritable: Bool
    public let fileSize: Int64?
    public let hasQuarantineAttributes: Bool
    public let sandboxPath: String?
    public let issues: [ConnectivityIssue]
    public let lastConnectionAttempt: Date
    public let connectionSuccess: Bool
  }

  // MARK: - Properties

  private let logger = Logger(subsystem: "com.record-thing", category: "database-connectivity")

  @Published public var currentMode: DatabaseMode = .production
  @Published public var diagnostics: DatabaseDiagnostics?
  @Published public var isConnected: Bool = false
  @Published public var lastError: Error?

  public static let shared = DatabaseConnectivityManager()

  // MARK: - Initialization

  private init() {
    logger.info("🔧 Initializing DatabaseConnectivityManager")
  }

  // MARK: - Public Interface

  /// Attempt to connect to database with automatic fallback strategy
  public func connectWithFallback() async -> (database: Blackbird.Database?, mode: DatabaseMode) {
    logger.info("🚀 Starting database connection with fallback strategy")

    // Try connection modes in priority order
    let connectionModes: [DatabaseMode] = [
      .debug,  // Highest priority for development
      .development,  // Git-tracked database
      .production,  // App Support folder
      .inMemory,  // In-memory fallback
      .bundled,  // Last resort (read-only)
    ]

    for mode in connectionModes {
      logger.info("🔍 Attempting connection in \(mode.displayName) mode")

      if let database = await attemptConnection(mode: mode) {
        await MainActor.run {
          self.currentMode = mode
          self.isConnected = true
        }
        logger.info("✅ Successfully connected in \(mode.displayName) mode")
        return (database, mode)
      }
    }

    logger.error("❌ All connection attempts failed")
    await MainActor.run {
      self.isConnected = false
    }
    return (nil, .production)
  }

  /// Attempt connection to specific database mode
  public func attemptConnection(mode: DatabaseMode) async -> Blackbird.Database? {
    let startTime = Date()
    var issues: [ConnectivityIssue] = []

    defer {
      // Update diagnostics after connection attempt
      Task { @MainActor in
        self.updateDiagnostics(mode: mode, issues: issues, connectionTime: startTime)
      }
    }

    do {
      switch mode {
      case .production:
        return try await connectToProduction(&issues)
      case .development:
        return try await connectToDevelopment(&issues)
      case .debug:
        return try await connectToDebug(&issues)
      case .inMemory:
        return try await connectToInMemory(&issues)
      case .bundled:
        return try await connectToBundled(&issues)
      }
    } catch {
      logger.error("❌ Connection failed for \(mode.displayName): \(error)")
      issues.append(.unknownError(error))
      await MainActor.run {
        self.lastError = error
      }
      return nil
    }
  }

  /// Get comprehensive diagnostics for current database state
  public func performDiagnostics() async -> DatabaseDiagnostics {
    logger.info("🔍 Performing comprehensive database diagnostics")

    let mode = currentMode
    let path = getDatabasePath(for: mode)
    var issues: [ConnectivityIssue] = []

    // Check file existence and permissions
    let exists = FileManager.default.fileExists(atPath: path)
    let isReadable = FileManager.default.isReadableFile(atPath: path)
    let isWritable = FileManager.default.isWritableFile(atPath: path)

    // Get file size
    let fileSize = try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64

    // Check quarantine attributes (macOS specific)
    let hasQuarantine = await checkQuarantineAttributes(path: path)
    if hasQuarantine {
      issues.append(.quarantineAttributes)
    }

    // Check sandbox path
    let sandboxPath = getSandboxContainerPath()

    // Validate sandbox permissions
    if mode == .production && !isPathInSandbox(path) {
      issues.append(.sandboxPermissions)
    }

    // Check journal file permissions
    if exists && isWritable {
      let journalPath = path + "-journal"
      let canCreateJournal = canCreateFile(at: journalPath)
      if !canCreateJournal {
        issues.append(.journalFileBlocked)
      }
    }

    // Check disk space
    if let availableSpace = getAvailableDiskSpace(at: path), availableSpace < 100_000_000 {  // 100MB
      issues.append(.diskSpace)
    }

    // Test database integrity
    if exists && isReadable {
      let isCorrupted = await testDatabaseIntegrity(path: path)
      if isCorrupted {
        issues.append(.corruptedDatabase)
      }
    }

    let diagnostics = DatabaseDiagnostics(
      mode: mode,
      path: path,
      exists: exists,
      isReadable: isReadable,
      isWritable: isWritable,
      fileSize: fileSize,
      hasQuarantineAttributes: hasQuarantine,
      sandboxPath: sandboxPath,
      issues: issues,
      lastConnectionAttempt: Date(),
      connectionSuccess: isConnected
    )

    await MainActor.run {
      self.diagnostics = diagnostics
    }

    return diagnostics
  }

  /// Remove quarantine attributes from bundled database (macOS specific)
  public func removeQuarantineAttributes(from path: String) async -> Bool {
    #if os(macOS)
      logger.info("🧹 Removing quarantine attributes from: \(path)")

      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
      process.arguments = ["-d", "com.apple.quarantine", path]

      do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
          logger.info("✅ Successfully removed quarantine attributes")
          return true
        } else {
          logger.warning("⚠️ xattr command failed with status: \(process.terminationStatus)")
          return false
        }
      } catch {
        logger.error("❌ Failed to remove quarantine attributes: \(error)")
        return false
      }
    #else
      return true  // Not applicable on iOS
    #endif
  }

  /// Create in-memory database clone from bundled database
  public func createInMemoryClone() async -> Blackbird.Database? {
    logger.info("🧠 Creating in-memory database clone")

    guard let bundlePath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
    else {
      logger.error("❌ Bundled database not found")
      return nil
    }

    do {
      // Create in-memory database
      let memoryDB = try Blackbird.Database(path: ":memory:")

      // Attach bundled database and copy data
      try await memoryDB.query("ATTACH DATABASE '\(bundlePath)' AS bundled")

      // Get list of tables from bundled database
      let tables = try await memoryDB.query(
        "SELECT name FROM bundled.sqlite_master WHERE type='table'")

      for table in tables {
        if let tableName = table["name"]?.stringValue {
          // Copy table structure
          let createSQL = try await memoryDB.query(
            "SELECT sql FROM bundled.sqlite_master WHERE name=?", tableName)
          if let sql = createSQL.first?["sql"]?.stringValue {
            try await memoryDB.query(sql)
          }

          // Copy table data
          try await memoryDB.query("INSERT INTO \(tableName) SELECT * FROM bundled.\(tableName)")
        }
      }

      // Detach bundled database
      try await memoryDB.query("DETACH DATABASE bundled")

      logger.info("✅ Successfully created in-memory database clone")
      return memoryDB

    } catch {
      logger.error("❌ Failed to create in-memory clone: \(error)")
      return nil
    }
  }

  // MARK: - Private Connection Methods

  private func connectToProduction(_ issues: inout [ConnectivityIssue]) async throws -> Blackbird
    .Database?
  {
    let appSupportPath = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("record-thing.sqlite")

    // Ensure App Support directory exists
    let appSupportDir = appSupportPath.deletingLastPathComponent()
    if !FileManager.default.fileExists(atPath: appSupportDir.path) {
      try FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
    }

    // Copy from bundle if database doesn't exist
    if !FileManager.default.fileExists(atPath: appSupportPath.platformPath) {
      try await copyBundledDatabase(to: appSupportPath)
    }

    return try Blackbird.Database(path: appSupportPath.platformPath)
  }

  private func connectToDevelopment(_ issues: inout [ConnectivityIssue]) async throws -> Blackbird
    .Database?
  {
    let devPath = "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"

    guard FileManager.default.fileExists(atPath: devPath) else {
      issues.append(.fileNotFound)
      throw NSError(
        domain: "DatabaseError", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Development database not found"])
    }

    return try Blackbird.Database(path: devPath)
  }

  private func connectToDebug(_ issues: inout [ConnectivityIssue]) async throws -> Blackbird
    .Database?
  {
    let debugPath = NSHomeDirectory() + "/Desktop/record-thing-debug.sqlite"

    guard FileManager.default.fileExists(atPath: debugPath) else {
      issues.append(.fileNotFound)
      throw NSError(
        domain: "DatabaseError", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Debug database not found"])
    }

    return try Blackbird.Database(path: debugPath)
  }

  private func connectToInMemory(_ issues: inout [ConnectivityIssue]) async throws -> Blackbird
    .Database?
  {
    return await createInMemoryClone()
  }

  private func connectToBundled(_ issues: inout [ConnectivityIssue]) async throws -> Blackbird
    .Database?
  {
    guard let bundlePath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
    else {
      issues.append(.fileNotFound)
      throw NSError(
        domain: "DatabaseError", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Bundled database not found"])
    }

    // Remove quarantine attributes if present
    let hasQuarantine = await checkQuarantineAttributes(path: bundlePath)
    if hasQuarantine {
      let removed = await removeQuarantineAttributes(from: bundlePath)
      if !removed {
        issues.append(.quarantineAttributes)
      }
    }

    return try Blackbird.Database(path: bundlePath)
  }

  // MARK: - Helper Methods

  private func getDatabasePath(for mode: DatabaseMode) -> String {
    switch mode {
    case .production:
      return getProductionDatabasePath()
    case .development:
      return "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
    case .debug:
      return NSHomeDirectory() + "/Desktop/record-thing-debug.sqlite"
    case .inMemory:
      return ":memory:"
    case .bundled:
      return Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite") ?? ""
    }
  }

  /// Get the production database path with proper containerization support
  private func getProductionDatabasePath() -> String {
    let fileManager = FileManager.default

    // Always use the runtime-determined App Support directory
    // This automatically handles containerization correctly
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let databaseURL = appSupportURL.appendingPathComponent("record-thing.sqlite")

    logger.info("📁 Production database path: \(databaseURL.platformPath)")
    logger.info("📁 App Support directory: \(appSupportURL.platformPath)")

    #if os(macOS)
      // Log additional containerization info for debugging
      if let bundleId = Bundle.main.bundleIdentifier {
        logger.info("📱 Bundle ID: \(bundleId)")
        let homeDir = NSHomeDirectory()
        let expectedContainer = "\(homeDir)/Library/Containers/\(bundleId)/Data"
        logger.info("📦 Expected container: \(expectedContainer)")

        // Check if we're actually in the expected container
        let actualPath = appSupportURL.platformPath
        if actualPath.contains(bundleId) {
          logger.info("✅ Database path correctly uses bundle ID container")
        } else {
          logger.warning("⚠️ Database path doesn't match expected container pattern")
        }
      }
    #endif

    return databaseURL.platformPath
  }

  private func getSandboxContainerPath() -> String? {
    #if os(macOS)
      // Get the app's bundle identifier
      guard let bundleId = Bundle.main.bundleIdentifier else { return nil }

      // Construct sandbox container path
      let homeDir = NSHomeDirectory()
      return "\(homeDir)/Library/Containers/\(bundleId)/Data"
    #else
      return nil
    #endif
  }

  private func isPathInSandbox(_ path: String) -> Bool {
    guard let sandboxPath = getSandboxContainerPath() else { return true }
    return path.hasPrefix(sandboxPath)
  }

  private func checkQuarantineAttributes(path: String) async -> Bool {
    #if os(macOS)
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
      process.arguments = ["-l", path]

      let pipe = Pipe()
      process.standardOutput = pipe

      do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        return output.contains("com.apple.quarantine")
      } catch {
        return false
      }
    #else
      return false
    #endif
  }

  private func canCreateFile(at path: String) -> Bool {
    let testData = Data("test".utf8)
    return FileManager.default.createFile(atPath: path, contents: testData, attributes: nil)
  }

  private func getAvailableDiskSpace(at path: String) -> Int64? {
    do {
      let url = URL(fileURLWithPath: path).deletingLastPathComponent()
      let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
      return values.volumeAvailableCapacity.map { Int64($0) }
    } catch {
      return nil
    }
  }

  private func testDatabaseIntegrity(path: String) async -> Bool {
    do {
      let testDB = try Blackbird.Database(path: path)
      let _ = try await testDB.query("PRAGMA integrity_check")
      return false  // No corruption
    } catch {
      return true  // Corrupted
    }
  }

  private func copyBundledDatabase(to destination: URL) async throws {
    guard let bundlePath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
    else {
      throw NSError(
        domain: "DatabaseError", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Bundled database not found"])
    }

    let sourceURL = URL(fileURLWithPath: bundlePath)

    // Remove quarantine attributes before copying
    let _ = await removeQuarantineAttributes(from: bundlePath)

    try FileManager.default.copyItem(at: sourceURL, to: destination)
    logger.info("✅ Copied bundled database to: \(destination.platformPath)")
  }

  private func updateDiagnostics(
    mode: DatabaseMode, issues: [ConnectivityIssue], connectionTime: Date
  ) {
    let path = getDatabasePath(for: mode)
    let exists = FileManager.default.fileExists(atPath: path)
    let isReadable = FileManager.default.isReadableFile(atPath: path)
    let isWritable = FileManager.default.isWritableFile(atPath: path)
    let fileSize = try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64

    diagnostics = DatabaseDiagnostics(
      mode: mode,
      path: path,
      exists: exists,
      isReadable: isReadable,
      isWritable: isWritable,
      fileSize: fileSize,
      hasQuarantineAttributes: false,  // Will be updated by full diagnostics
      sandboxPath: getSandboxContainerPath(),
      issues: issues,
      lastConnectionAttempt: connectionTime,
      connectionSuccess: isConnected
    )
  }
}
