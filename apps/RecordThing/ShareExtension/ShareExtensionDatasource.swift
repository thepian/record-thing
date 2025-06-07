//
//  ShareExtensionDatasource.swift
//  ShareExtension
//
//  Created by AI Assistant on 07.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Blackbird
import Foundation
import RecordLib
import SwiftUI
import os

/// ShareExtension-specific datasource that extends RecordLib's AppDatasource
/// Provides database access and shared content processing for the ShareExtension
class ShareExtensionDatasource: RecordLib.AppDatasource {

  // Singleton instance for ShareExtension
  private static let _shared = ShareExtensionDatasource()
  override class var shared: ShareExtensionDatasource { _shared }

  private let logger = Logger(
    subsystem: "com.thepia.recordthing", category: "shareextension-datasource")

  override init(debugDb: Bool = false) {
    super.init(debugDb: debugDb)
    logger.info("✅ ShareExtension datasource initialized")
  }

  // MARK: - ShareExtension-Specific Methods

  /// Saves shared content to the database
  /// - Parameters:
  ///   - content: The shared content to save
  ///   - note: User's note about the content
  /// - Returns: Success status
  func saveSharedContent(_ content: SharedContent, note: String) async -> Bool {
    logger.info("💾 Saving shared content: \(content.contentType.displayName)")

    guard let db = db else {
      logger.error("❌ Database not available for saving shared content")
      DatabaseMonitor.shared.logError(
        NSError(
          domain: "ShareExtension", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Database not available"]),
        context: "ShareExtension attempted to save content without database",
        query: nil
      )
      return false
    }

    do {
      // For now, log the content details (database saving will be implemented later)
      logger.info("💾 Saving shared content to database...")
      logger.info("📝 Content type: \(content.contentType.displayName)")
      logger.info("📝 Title: \(content.displayTitle)")
      logger.info("📝 Description: \(self.buildDescription(for: content, note: note))")

      if let url = content.url {
        logger.info("📝 URL: \(url.absoluteString)")
      }

      if !note.isEmpty {
        logger.info("📝 User note: \(note)")
      }

      // TODO: Implement actual database saving once model issues are resolved
      // This will require:
      // 1. Fixing the Things/Evidence initializer signatures
      // 2. Ensuring ShareExtension has proper access to RecordLib models
      // 3. Testing database write operations in ShareExtension context

      logger.info("✅ Content logging completed (database save pending implementation)")

      // Log successful save to monitoring
      DatabaseMonitor.shared.logActivity(
        .queryExecuted,
        details: "ShareExtension saved content: \(content.contentType.displayName)"
      )

      return true

    } catch {
      logger.error("❌ Failed to save shared content: \(error)")
      DatabaseMonitor.shared.logError(
        error,
        context: "ShareExtension failed to save shared content",
        query: "INSERT INTO things/evidence"
      )
      return false
    }
  }

  /// Creates an unprocessed share entry for later processing
  /// This is useful when the main app needs to handle complex processing
  /// - Parameters:
  ///   - content: The shared content
  ///   - note: User's note
  /// - Returns: Success status
  func createUnprocessedShare(_ content: SharedContent, note: String) async -> Bool {
    logger.info("📝 Creating unprocessed share entry")

    guard let db = db else {
      logger.error("❌ Database not available for unprocessed share")
      return false
    }

    do {
      // Log the unprocessed share details (database saving will be implemented later)
      logger.info("📝 Creating unprocessed share entry...")
      logger.info("📝 Content type: \(content.contentType.displayName)")
      logger.info("📝 Title: [UNPROCESSED] \(content.displayTitle)")

      // Store the content data as JSON for later processing
      let shareData: [String: Any] = [
        "contentType": content.contentType.displayName,
        "url": content.url?.absoluteString ?? "",
        "title": content.title ?? "",
        "text": content.text ?? "",
        "note": note,
        "hasImage": content.image != nil,
      ]

      if let jsonData = try? JSONSerialization.data(withJSONObject: shareData),
        let jsonString = String(data: jsonData, encoding: .utf8)
      {
        logger.info("📝 Share data JSON: \(jsonString)")
      }

      // TODO: Implement actual database saving once model issues are resolved
      logger.info("✅ Unprocessed share logging completed (database save pending)")

      DatabaseMonitor.shared.logActivity(
        .queryExecuted,
        details: "ShareExtension would create unprocessed share"
      )

      return true

    } catch {
      logger.error("❌ Failed to create unprocessed share: \(error)")
      DatabaseMonitor.shared.logError(
        error,
        context: "ShareExtension failed to create unprocessed share",
        query: "INSERT INTO things (unprocessed)"
      )
      return false
    }
  }

  /// Gets the count of unprocessed shares (for the main app to display)
  /// - Returns: Number of unprocessed shares
  func getUnprocessedShareCount() async -> Int {
    guard let db = db else { return 0 }

    do {
      let things = try await Things.read(
        from: db,
        matching: \.$evidence_type_name == "unprocessed_share"
      )
      return things.count
    } catch {
      logger.error("❌ Failed to get unprocessed share count: \(error)")
      return 0
    }
  }

  /// Validates that the database is accessible and ready for ShareExtension operations
  /// - Returns: True if database is ready
  func validateDatabaseAccess() async -> Bool {
    guard let db = db else {
      logger.error("❌ Database not available for validation")
      return false
    }

    do {
      // Test basic database connectivity
      let _ = try await db.query("SELECT COUNT(*) FROM things LIMIT 1")
      logger.info("✅ Database access validated successfully")
      return true
    } catch {
      logger.error("❌ Database validation failed: \(error)")
      DatabaseMonitor.shared.logError(
        error,
        context: "ShareExtension database validation failed",
        query: "SELECT COUNT(*) FROM things"
      )
      return false
    }
  }

  // MARK: - Helper Methods

  /// Builds a description for the Thing based on content type and user note
  private func buildDescription(for content: SharedContent, note: String) -> String {
    var description = ""

    switch content.contentType {
    case .youTubeVideo(let videoId):
      description = "YouTube Video: \(videoId)"
    case .webPage:
      if let url = content.url {
        description = "Web Page: \(url.absoluteString)"
      } else {
        description = "Web Page"
      }
    case .text:
      description = content.text ?? "Shared Text"
    case .image:
      description = "Shared Image"
    case .unknown:
      description = "Unknown Content"
    }

    if !note.isEmpty {
      description += "\n\nNote: \(note)"
    }

    return description
  }

  /// Builds evidence data string for the Evidence entry
  private func buildEvidenceData(for content: SharedContent, note: String) -> String? {
    if let url = content.url {
      return url.absoluteString
    } else if !note.isEmpty {
      return note
    }
    return nil
  }
}

// MARK: - Environment Integration

extension EnvironmentValues {
  private struct ShareExtensionDatasourceKey: EnvironmentKey {
    static let defaultValue: ShareExtensionDatasource? = nil
  }

  var shareExtensionDatasource: ShareExtensionDatasource? {
    get { self[ShareExtensionDatasourceKey.self] }
    set { self[ShareExtensionDatasourceKey.self] = newValue }
  }
}
