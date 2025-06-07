//
//  SimpleiCloudManager.swift
//  RecordLib
//
//  Created by Assistant on 07.06.2025.
//

import Combine
import Foundation
import SwiftUI
import os

/// Simplified iCloud Documents manager that leverages automatic iOS syncing
/// With proper entitlements (CloudDocuments), files in Documents folder sync automatically
///
/// For comprehensive documentation, see: docs/ICLOUD_SYNC.md
/// For debug interface, use: SimpleiCloudDebugView in Settings → Sync & Backup → iCloud Debug
@MainActor
public class SimpleiCloudManager: ObservableObject {
  public static let shared = SimpleiCloudManager()

  private let logger = Logger(subsystem: "com.record-thing", category: "icloud-simple")
  private let fileManager = FileManager.default
  private var metadataQuery: NSMetadataQuery?
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Published Properties

  @Published public private(set) var isAvailable = false
  @Published public private(set) var isEnabled = false
  @Published public private(set) var documentStates: [String: SimpleDocumentState] = [:]
  @Published public private(set) var totalDocuments = 0
  @Published public private(set) var syncedDocuments = 0
  @Published public private(set) var pendingDocuments = 0

  // MARK: - URLs

  public private(set) var iCloudContainerURL: URL?
  public private(set) var documentsURL: URL

  // MARK: - Initialization

  private init() {
    // Get the app's Documents directory (automatically synced if entitlements are correct)
    documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    // Check iCloud availability
    checkiCloudAvailability()

    // Start monitoring if available
    if self.isAvailable {
      startMonitoring()
    }

    logger.info("SimpleiCloudManager initialized - Available: \(self.isAvailable)")
  }

  // MARK: - Setup

  private func checkiCloudAvailability() {
    // Check if iCloud container is available
    iCloudContainerURL = fileManager.url(forUbiquityContainerIdentifier: nil)
    isAvailable = iCloudContainerURL != nil

    if self.isAvailable {
      logger.info("iCloud container available at: \(self.iCloudContainerURL?.path ?? "Unknown")")
    } else {
      logger.warning("iCloud container not available - check entitlements and iCloud settings")
    }
  }

  // MARK: - Monitoring

  private func startMonitoring() {
    guard isAvailable else { return }

    // Set up metadata query to monitor document sync status
    metadataQuery = NSMetadataQuery()
    metadataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
    metadataQuery?.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)

    // Observe query updates
    NotificationCenter.default.publisher(for: .NSMetadataQueryDidUpdate)
      .sink { [weak self] _ in
        Task { @MainActor in
          self?.processMetadataQueryResults()
        }
      }
      .store(in: &cancellables)

    NotificationCenter.default.publisher(for: .NSMetadataQueryDidFinishGathering)
      .sink { [weak self] _ in
        Task { @MainActor in
          self?.processMetadataQueryResults()
        }
      }
      .store(in: &cancellables)

    metadataQuery?.start()
    logger.info("Started iCloud document monitoring")
  }

  private func processMetadataQueryResults() {
    guard let query = metadataQuery else { return }

    var states: [String: SimpleDocumentState] = [:]
    var total = 0
    var synced = 0
    var pending = 0

    for i in 0..<query.resultCount {
      guard let item = query.result(at: i) as? NSMetadataItem else { continue }

      let fileName = item.value(forAttribute: NSMetadataItemFSNameKey) as? String ?? "Unknown"
      let downloadStatus =
        item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
      let hasConflicts =
        item.value(forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey) as? Bool
        ?? false
      let uploadingError =
        item.value(forAttribute: NSMetadataUbiquitousItemUploadingErrorKey) as? Error
      let downloadingError =
        item.value(forAttribute: NSMetadataUbiquitousItemDownloadingErrorKey) as? Error

      let state = SimpleDocumentState(
        fileName: fileName,
        downloadStatus: downloadStatus,
        hasConflicts: hasConflicts,
        uploadingError: uploadingError,
        downloadingError: downloadingError
      )

      states[fileName] = state
      total += 1

      if state.isSynced {
        synced += 1
      } else {
        pending += 1
      }
    }

    documentStates = states
    totalDocuments = total
    syncedDocuments = synced
    pendingDocuments = pending

    logger.debug("iCloud status: \(synced)/\(total) synced, \(pending) pending")
  }

  // MARK: - Public API

  /// Enable iCloud syncing (just sets the flag - actual syncing is automatic)
  public func enableSync() {
    guard isAvailable else {
      logger.warning("Cannot enable sync: iCloud not available")
      return
    }

    isEnabled = true
    UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")
    logger.info("iCloud sync enabled - files will sync automatically")
  }

  /// Disable iCloud syncing
  public func disableSync() {
    isEnabled = false
    UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")
    logger.info("iCloud sync disabled")
  }

  /// Get the Documents directory URL (automatically synced if iCloud is enabled)
  public func getDocumentsURL() -> URL {
    return documentsURL
  }

  /// Check if a specific file is synced
  public func isFileSynced(_ fileName: String) -> Bool {
    return documentStates[fileName]?.isSynced ?? false
  }

  /// Get sync status for a specific file
  public func getFileStatus(_ fileName: String) -> String {
    return documentStates[fileName]?.statusDescription ?? "Unknown"
  }

  /// Force download a file (if it's not already downloaded)
  public func downloadFile(at url: URL) throws {
    guard isAvailable else {
      throw SimpleiCloudError.iCloudUnavailable
    }

    try fileManager.startDownloadingUbiquitousItem(at: url)
    logger.info("Started downloading file: \(url.lastPathComponent)")
  }

  /// Move a file to iCloud (if not already there)
  public func moveToiCloud(fileAt url: URL) throws {
    guard isAvailable else {
      throw SimpleiCloudError.iCloudUnavailable
    }

    var isUbiquitous = false
    do {
      let resourceValues = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
      isUbiquitous = resourceValues.ubiquitousItemDownloadingStatus != nil
    } catch {
      // File is not ubiquitous
    }

    if !isUbiquitous {
      try fileManager.setUbiquitous(true, itemAt: url, destinationURL: url)
      logger.info("Moved file to iCloud: \(url.lastPathComponent)")
    }
  }
}

// MARK: - Supporting Types

public enum SimpleiCloudError: LocalizedError {
  case iCloudUnavailable
  case fileNotFound
  case syncDisabled

  public var errorDescription: String? {
    switch self {
    case .iCloudUnavailable:
      return "iCloud is not available"
    case .fileNotFound:
      return "File not found"
    case .syncDisabled:
      return "iCloud sync is disabled"
    }
  }
}

public struct SimpleDocumentState {
  public let fileName: String
  public let downloadStatus: String?
  public let hasConflicts: Bool
  public let uploadingError: Error?
  public let downloadingError: Error?

  public var isSynced: Bool {
    return downloadStatus == NSMetadataUbiquitousItemDownloadingStatusDownloaded && !hasConflicts
      && uploadingError == nil && downloadingError == nil
  }

  public var hasError: Bool {
    return uploadingError != nil || downloadingError != nil
  }

  public var statusDescription: String {
    if hasError {
      return "Error"
    } else if hasConflicts {
      return "Conflict"
    } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusDownloaded {
      return "Synced"
    } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
      return "Not Downloaded"
    } else {
      return "Syncing"
    }
  }
}

// MARK: - Convenience Extensions

extension SimpleiCloudManager {

  /// Create a file in the Documents directory (will automatically sync to iCloud)
  public func createFile(named fileName: String, content: Data) throws -> URL {
    let fileURL = documentsURL.appendingPathComponent(fileName)
    try content.write(to: fileURL)

    // If iCloud is available, ensure the file is set to sync
    if isAvailable && isEnabled {
      try moveToiCloud(fileAt: fileURL)
    }

    logger.info("Created file: \(fileName)")
    return fileURL
  }

  /// Create a text file in the Documents directory
  public func createTextFile(named fileName: String, content: String) throws -> URL {
    guard let data = content.data(using: .utf8) else {
      throw SimpleiCloudError.fileNotFound
    }
    return try createFile(named: fileName, content: data)
  }

  /// Get all files in the Documents directory
  public func getAllDocuments() throws -> [URL] {
    let contents = try fileManager.contentsOfDirectory(
      at: documentsURL, includingPropertiesForKeys: nil)
    return contents.filter { !$0.hasDirectoryPath }
  }

  /// Get sync summary
  public func getSyncSummary() -> String {
    return "\(syncedDocuments)/\(totalDocuments) files synced (\(pendingDocuments) pending)"
  }
}
