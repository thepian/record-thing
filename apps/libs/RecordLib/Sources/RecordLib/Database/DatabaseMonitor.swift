//
//  DatabaseMonitor.swift
//  RecordLib
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Blackbird
import Foundation
import SwiftUI
import os

/// Database activity tracking and error monitoring
public class DatabaseMonitor: ObservableObject {
  public static let shared = DatabaseMonitor()

  private let logger = Logger(subsystem: "com.record-thing", category: "database")

  // MARK: - Published Properties

  @Published public private(set) var activities: [DatabaseActivity] = []
  @Published public private(set) var currentStatus: DatabaseStatus = .unknown
  @Published public private(set) var lastError: DatabaseError?
  @Published public private(set) var connectionInfo: DatabaseConnectionInfo?
  @Published public private(set) var isHealthy: Bool = false

  // MARK: - Configuration

  private let maxActivities = 100  // Keep last 100 activities
  private let healthCheckInterval: TimeInterval = 30  // Check every 30 seconds
  private var healthCheckTimer: Timer?

  private init() {
    startHealthMonitoring()
  }

  deinit {
    healthCheckTimer?.invalidate()
  }

  // MARK: - Activity Tracking

  /// Log a database activity
  public func logActivity(_ type: DatabaseActivityType, details: String? = nil, error: Error? = nil)
  {
    let activity = DatabaseActivity(
      type: type,
      timestamp: Date(),
      details: details,
      error: error
    )

    DispatchQueue.main.async {
      self.activities.insert(activity, at: 0)

      // Keep only the most recent activities
      if self.activities.count > self.maxActivities {
        self.activities = Array(self.activities.prefix(self.maxActivities))
      }

      // Update status based on activity
      self.updateStatusFromActivity(activity)
    }

    // Log to system logger
    if let error = error {
      logger.error(
        "Database \(type.rawValue): \(details ?? "No details") - Error: \(error.localizedDescription)"
      )
    } else {
      logger.info("Database \(type.rawValue): \(details ?? "No details")")
    }
  }

  /// Update connection information
  public func updateConnectionInfo(_ info: DatabaseConnectionInfo) {
    DispatchQueue.main.async {
      self.connectionInfo = info
      self.logActivity(.connectionEstablished, details: "Connected to: \(info.path)")
    }
  }

  /// Log a database error with detailed information
  public func logError(_ error: Error, context: String? = nil, query: String? = nil) {
    let dbError = DatabaseError(
      error: error,
      context: context,
      query: query,
      timestamp: Date(),
      connectionInfo: connectionInfo
    )

    DispatchQueue.main.async {
      self.lastError = dbError
      self.isHealthy = false
    }

    let details = [context, query].compactMap { $0 }.joined(separator: " | ")
    logActivity(.error, details: details.isEmpty ? nil : details, error: error)
  }

  // MARK: - Health Monitoring

  private func startHealthMonitoring() {
    healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) {
      [weak self] _ in
      Task { @MainActor in
        self?.performHealthCheck()
      }
    }
  }

  private func performHealthCheck() {
    // This will be implemented by the concrete AppDatasource
    // For now, we'll just check if we have a connection
    if connectionInfo != nil {
      currentStatus = .connected
      isHealthy = true
    } else {
      currentStatus = .disconnected
      isHealthy = false
    }
  }

  /// Manually trigger a health check
  public func checkHealth() {
    performHealthCheck()
  }

  /// Set a custom health check function
  public func setHealthCheckFunction(_ healthCheck: @escaping () async throws -> Void) {
    healthCheckTimer?.invalidate()
    healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) {
      [weak self] _ in
      Task { @MainActor in
        guard let self = self else { return }
        do {
          try await healthCheck()
          self.currentStatus = .connected
          self.isHealthy = true
        } catch {
          self.currentStatus = .error
          self.isHealthy = false
          self.logError(error, context: "Health check failed")
        }
      }
    }
  }

  // MARK: - Status Management

  private func updateStatusFromActivity(_ activity: DatabaseActivity) {
    switch activity.type {
    case .connectionEstablished:
      currentStatus = .connected
      isHealthy = true
    case .connectionLost, .error:
      currentStatus = .error
      isHealthy = false
    case .databaseReset, .databaseReloaded, .databaseBackup:
      currentStatus = .connected
      isHealthy = true
    default:
      break
    }
  }

  // MARK: - Utility Methods

  /// Clear all activities (for debugging)
  public func clearActivities() {
    DispatchQueue.main.async {
      self.activities.removeAll()
      self.logActivity(.debugAction, details: "Activities cleared")
    }
  }

  /// Get activities of a specific type
  public func activities(ofType type: DatabaseActivityType) -> [DatabaseActivity] {
    return activities.filter { $0.type == type }
  }

  /// Get recent errors
  public func recentErrors(limit: Int = 10) -> [DatabaseActivity] {
    return activities.filter { $0.error != nil }.prefix(limit).map { $0 }
  }

  /// Get summary statistics
  public func getStatistics() -> DatabaseStatistics {
    let errorCount = activities.filter { $0.error != nil }.count
    let connectionCount = activities.filter { $0.type == .connectionEstablished }.count
    let queryCount = activities.filter { $0.type == .queryExecuted }.count

    return DatabaseStatistics(
      totalActivities: activities.count,
      errorCount: errorCount,
      connectionCount: connectionCount,
      queryCount: queryCount,
      uptime: connectionInfo.map { Date().timeIntervalSince($0.connectedAt) },
      isHealthy: isHealthy
    )
  }
}

// MARK: - Data Models

public struct DatabaseActivity: Identifiable {
  public let id = UUID()
  public let type: DatabaseActivityType
  public let timestamp: Date
  public let details: String?
  public let error: Error?

  public var formattedTimestamp: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: timestamp)
  }

  public var statusIcon: String {
    switch type {
    case .connectionEstablished:
      return "checkmark.circle.fill"
    case .connectionLost, .error:
      return "xmark.circle.fill"
    case .databaseReset, .databaseReloaded:
      return "arrow.clockwise.circle.fill"
    case .databaseBackup:
      return "externaldrive.fill"
    case .queryExecuted:
      return "magnifyingglass.circle"
    case .debugAction:
      return "wrench.and.screwdriver.fill"
    case .migrationStarted, .migrationCompleted:
      return "arrow.up.circle.fill"
    }
  }

  public var statusColor: Color {
    switch type {
    case .connectionEstablished, .databaseReloaded, .migrationCompleted, .databaseBackup:
      return .green
    case .connectionLost, .error:
      return .red
    case .databaseReset, .migrationStarted:
      return .orange
    case .queryExecuted, .debugAction:
      return .blue
    }
  }
}

public enum DatabaseActivityType: String, CaseIterable {
  case connectionEstablished = "Connection Established"
  case connectionLost = "Connection Lost"
  case databaseReset = "Database Reset"
  case databaseReloaded = "Database Reloaded"
  case databaseBackup = "Database Backup"
  case queryExecuted = "Query Executed"
  case error = "Error"
  case migrationStarted = "Migration Started"
  case migrationCompleted = "Migration Completed"
  case debugAction = "Debug Action"
}

public enum DatabaseStatus {
  case unknown
  case connected
  case disconnected
  case error

  public var displayName: String {
    switch self {
    case .unknown: return "Unknown"
    case .connected: return "Connected"
    case .disconnected: return "Disconnected"
    case .error: return "Error"
    }
  }

  public var color: Color {
    switch self {
    case .unknown: return .gray
    case .connected: return .green
    case .disconnected: return .orange
    case .error: return .red
    }
  }
}

public struct DatabaseConnectionInfo {
  public let path: String
  public let type: DatabaseType
  public let connectedAt: Date
  public let fileSize: Int64?
  public let isReadOnly: Bool

  public init(
    path: String, type: DatabaseType, connectedAt: Date, fileSize: Int64?, isReadOnly: Bool
  ) {
    self.path = path
    self.type = type
    self.connectedAt = connectedAt
    self.fileSize = fileSize
    self.isReadOnly = isReadOnly
  }

  public enum DatabaseType {
    case development
    case debug
    case production
    case bundled

    public var displayName: String {
      switch self {
      case .development: return "Development"
      case .debug: return "Debug"
      case .production: return "Production"
      case .bundled: return "Bundled Default"
      }
    }
  }
}

public struct DatabaseError {
  public let error: Error
  public let context: String?
  public let query: String?
  public let timestamp: Date
  public let connectionInfo: DatabaseConnectionInfo?

  public init(
    error: Error, context: String?, query: String?, timestamp: Date,
    connectionInfo: DatabaseConnectionInfo?
  ) {
    self.error = error
    self.context = context
    self.query = query
    self.timestamp = timestamp
    self.connectionInfo = connectionInfo
  }

  public var blackbirdErrorCode: Int? {
    // Extract Blackbird/SQLite error code if available
    let errorString = error.localizedDescription
    if errorString.contains("error") {
      // Try to extract error number from strings like "Blackbird.Database.Error error 7"
      let pattern = #"error (\d+)"#
      if let regex = try? NSRegularExpression(pattern: pattern),
        let match = regex.firstMatch(
          in: errorString, range: NSRange(errorString.startIndex..., in: errorString)),
        let range = Range(match.range(at: 1), in: errorString)
      {
        return Int(errorString[range])
      }
    }
    return nil
  }

  public var sqliteErrorDescription: String? {
    guard let code = blackbirdErrorCode else { return nil }

    // SQLite error codes
    switch code {
    case 1: return "SQLITE_ERROR - Generic error"
    case 2: return "SQLITE_INTERNAL - Internal logic error"
    case 3: return "SQLITE_PERM - Access permission denied"
    case 4: return "SQLITE_ABORT - Callback routine requested an abort"
    case 5: return "SQLITE_BUSY - Database file is locked"
    case 6: return "SQLITE_LOCKED - Database table is locked"
    case 7: return "SQLITE_NOMEM - Out of memory"
    case 8: return "SQLITE_READONLY - Attempt to write a readonly database"
    case 9: return "SQLITE_INTERRUPT - Operation was interrupted"
    case 10: return "SQLITE_IOERR - Disk I/O error occurred"
    case 11: return "SQLITE_CORRUPT - Database disk image is malformed"
    case 12: return "SQLITE_NOTFOUND - Unknown opcode in sqlite3_file_control()"
    case 13: return "SQLITE_FULL - Insertion failed because database is full"
    case 14: return "SQLITE_CANTOPEN - Unable to open the database file"
    case 15: return "SQLITE_PROTOCOL - Database lock protocol error"
    case 16: return "SQLITE_EMPTY - Internal use only"
    case 17: return "SQLITE_SCHEMA - Database schema changed"
    case 18: return "SQLITE_TOOBIG - String or BLOB exceeds size limit"
    case 19: return "SQLITE_CONSTRAINT - Abort due to constraint violation"
    case 20: return "SQLITE_MISMATCH - Data type mismatch"
    case 21: return "SQLITE_MISUSE - Library used incorrectly"
    case 22: return "SQLITE_NOLFS - Uses OS features not supported on host"
    case 23: return "SQLITE_AUTH - Authorization denied"
    case 24: return "SQLITE_FORMAT - Not used"
    case 25: return "SQLITE_RANGE - 2nd parameter to sqlite3_bind out of range"
    case 26: return "SQLITE_NOTADB - File opened that is not a database file"
    default: return "Unknown SQLite error code: \(code)"
    }
  }
}

public struct DatabaseStatistics {
  public let totalActivities: Int
  public let errorCount: Int
  public let connectionCount: Int
  public let queryCount: Int
  public let uptime: TimeInterval?
  public let isHealthy: Bool

  public init(
    totalActivities: Int, errorCount: Int, connectionCount: Int, queryCount: Int,
    uptime: TimeInterval?, isHealthy: Bool
  ) {
    self.totalActivities = totalActivities
    self.errorCount = errorCount
    self.connectionCount = connectionCount
    self.queryCount = queryCount
    self.uptime = uptime
    self.isHealthy = isHealthy
  }

  public var errorRate: Double {
    guard totalActivities > 0 else { return 0 }
    return Double(errorCount) / Double(totalActivities)
  }

  public var formattedUptime: String? {
    guard let uptime = uptime else { return nil }

    let hours = Int(uptime) / 3600
    let minutes = Int(uptime) % 3600 / 60
    let seconds = Int(uptime) % 60

    if hours > 0 {
      return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
      return String(format: "%dm %ds", minutes, seconds)
    } else {
      return String(format: "%ds", seconds)
    }
  }
}
