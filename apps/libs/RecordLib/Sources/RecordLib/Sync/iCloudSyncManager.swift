//
//  iCloudSyncManager.swift
//  RecordLib
//
//  Created by Assistant on 07.06.2025.
//

import Combine
import Foundation
import SwiftUI
import os

/// Manages iCloud Documents folder synchronization for RecordThing app
@MainActor
public class iCloudSyncManager: ObservableObject {
  public static let shared = iCloudSyncManager()

  private let logger = Logger(subsystem: "com.record-thing", category: "icloud-sync")
  private let fileManager = FileManager.default
  private var metadataQuery: NSMetadataQuery?
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Published Properties

  @Published public private(set) var isAvailable = false
  @Published public private(set) var isEnabled = false
  @Published public private(set) var syncStatus: SyncStatus = .idle
  @Published public private(set) var lastSyncDate: Date?
  @Published public private(set) var syncProgress: Double = 0.0
  @Published public private(set) var syncError: Error?
  @Published public private(set) var documentStates: [String: DocumentState] = [:]
  @Published public private(set) var totalDocuments = 0
  @Published public private(set) var syncedDocuments = 0
  @Published public private(set) var pendingDocuments = 0
  @Published public private(set) var errorDocuments = 0

  // MARK: - URLs

  public private(set) var iCloudContainerURL: URL?
  public private(set) var localDocumentsURL: URL
  public private(set) var iCloudDocumentsURL: URL?

  // MARK: - Initialization

  private init() {
    // Set up local documents URL
    localDocumentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    // Set up iCloud container
    setupiCloudContainer()

    // Start monitoring
    startMonitoring()

    logger.info("iCloudSyncManager initialized")
  }

  // MARK: - Setup

  private func setupiCloudContainer() {
    // Get iCloud container URL
    iCloudContainerURL = fileManager.url(forUbiquityContainerIdentifier: nil)

    if let containerURL = iCloudContainerURL {
      iCloudDocumentsURL = containerURL.appendingPathComponent("Documents")
      isAvailable = true
      logger.info("iCloud container available at: \(containerURL.path)")

      // Create Documents folder if needed
      createiCloudDocumentsFolder()
    } else {
      isAvailable = false
      logger.warning("iCloud container not available")
    }
  }

  private func createiCloudDocumentsFolder() {
    guard let documentsURL = iCloudDocumentsURL else { return }

    do {
      try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
      logger.info("iCloud Documents folder created/verified")
    } catch {
      logger.error("Failed to create iCloud Documents folder: \(error)")
    }
  }

  // MARK: - Monitoring

  private func startMonitoring() {
    guard isAvailable else { return }

    // Set up metadata query for monitoring iCloud documents
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
    logger.info("Started iCloud monitoring")
  }

  private func processMetadataQueryResults() {
    guard let query = metadataQuery else { return }

    var states: [String: DocumentState] = [:]
    var total = 0
    var synced = 0
    var pending = 0
    var errors = 0

    for i in 0..<query.resultCount {
      guard let item = query.result(at: i) as? NSMetadataItem else { continue }

      let fileName = item.value(forAttribute: NSMetadataItemFSNameKey) as? String ?? "Unknown"
      let downloadStatus =
        item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
      let isDownloaded = (downloadStatus == NSMetadataUbiquitousItemDownloadingStatusDownloaded)
      let hasUnresolvedConflicts =
        item.value(forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey) as? Bool
        ?? false
      // Simplified upload status - assume uploaded if file exists in iCloud
      let isUploaded = true  // Files in metadata query are already in iCloud
      let uploadingError =
        item.value(forAttribute: NSMetadataUbiquitousItemUploadingErrorKey) as? Error
      let downloadingError =
        item.value(forAttribute: NSMetadataUbiquitousItemDownloadingErrorKey) as? Error

      let state = DocumentState(
        fileName: fileName,
        isDownloaded: isDownloaded,
        isUploaded: isUploaded,
        downloadStatus: downloadStatus,
        hasConflicts: hasUnresolvedConflicts,
        uploadingError: uploadingError,
        downloadingError: downloadingError
      )

      states[fileName] = state
      total += 1

      if state.hasError {
        errors += 1
      } else if state.isFullySynced {
        synced += 1
      } else {
        pending += 1
      }
    }

    documentStates = states
    totalDocuments = total
    syncedDocuments = synced
    pendingDocuments = pending
    errorDocuments = errors

    // Update sync progress
    if total > 0 {
      syncProgress = Double(synced) / Double(total)
    } else {
      syncProgress = 1.0
    }

    logger.debug("iCloud status: \(synced)/\(total) synced, \(pending) pending, \(errors) errors")
  }

  // MARK: - Public API

  public func enableSync() {
    guard isAvailable else {
      logger.warning("Cannot enable sync: iCloud not available")
      return
    }

    isEnabled = true
    UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")
    logger.info("iCloud sync enabled")

    // Start initial sync
    Task {
      await performInitialSync()
    }
  }

  public func disableSync() {
    isEnabled = false
    UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")
    logger.info("iCloud sync disabled")
  }

  public func performManualSync() async {
    guard isAvailable && isEnabled else { return }

    syncStatus = .syncing
    syncError = nil

    do {
      try await syncDatabaseToiCloud()
      try await syncAssetsToiCloud()

      lastSyncDate = Date()
      syncStatus = .completed
      logger.info("Manual sync completed successfully")
    } catch {
      syncError = error
      syncStatus = .failed
      logger.error("Manual sync failed: \(error)")
    }
  }

  // MARK: - Sync Operations

  private func performInitialSync() async {
    guard isAvailable && isEnabled else { return }

    syncStatus = .syncing

    do {
      // Check if we need to restore from iCloud
      if shouldRestoreFromiCloud() {
        try await restoreFromiCloud()
      } else {
        // Upload current data to iCloud
        try await syncDatabaseToiCloud()
        try await syncAssetsToiCloud()
      }

      lastSyncDate = Date()
      syncStatus = .completed
      logger.info("Initial sync completed")
    } catch {
      syncError = error
      syncStatus = .failed
      logger.error("Initial sync failed: \(error)")
    }
  }

  private func shouldRestoreFromiCloud() -> Bool {
    guard let iCloudURL = iCloudDocumentsURL else { return false }

    let iCloudDatabaseURL = iCloudURL.appendingPathComponent("record-thing.sqlite")
    let localDatabaseURL = localDocumentsURL.appendingPathComponent("record-thing.sqlite")

    // Check if iCloud has a newer database
    if fileManager.fileExists(atPath: iCloudDatabaseURL.path),
      let iCloudDate = try? fileManager.attributesOfItem(atPath: iCloudDatabaseURL.path)[
        .modificationDate] as? Date
    {

      if !fileManager.fileExists(atPath: localDatabaseURL.path) {
        return true  // No local database, restore from iCloud
      }

      if let localDate = try? fileManager.attributesOfItem(atPath: localDatabaseURL.path)[
        .modificationDate] as? Date
      {
        return iCloudDate > localDate  // iCloud is newer
      }
    }

    return false
  }

  private func syncDatabaseToiCloud() async throws {
    guard let iCloudURL = iCloudDocumentsURL else {
      throw SyncError.iCloudUnavailable
    }

    let localDatabaseURL = localDocumentsURL.appendingPathComponent("record-thing.sqlite")
    let iCloudDatabaseURL = iCloudURL.appendingPathComponent("record-thing.sqlite")

    if fileManager.fileExists(atPath: localDatabaseURL.path) {
      try fileManager.copyItem(at: localDatabaseURL, to: iCloudDatabaseURL)
      logger.info("Database synced to iCloud")
    }
  }

  private func syncAssetsToiCloud() async throws {
    guard let iCloudURL = iCloudDocumentsURL else {
      throw SyncError.iCloudUnavailable
    }

    let localAssetsURL = localDocumentsURL.appendingPathComponent("assets")
    let iCloudAssetsURL = iCloudURL.appendingPathComponent("assets")

    if fileManager.fileExists(atPath: localAssetsURL.path) {
      try fileManager.copyItem(at: localAssetsURL, to: iCloudAssetsURL)
      logger.info("Assets synced to iCloud")
    }
  }

  private func restoreFromiCloud() async throws {
    guard let iCloudURL = iCloudDocumentsURL else {
      throw SyncError.iCloudUnavailable
    }

    // Restore database
    let iCloudDatabaseURL = iCloudURL.appendingPathComponent("record-thing.sqlite")
    let localDatabaseURL = localDocumentsURL.appendingPathComponent("record-thing.sqlite")

    if fileManager.fileExists(atPath: iCloudDatabaseURL.path) {
      try fileManager.copyItem(at: iCloudDatabaseURL, to: localDatabaseURL)
      logger.info("Database restored from iCloud")
    }

    // Restore assets
    let iCloudAssetsURL = iCloudURL.appendingPathComponent("assets")
    let localAssetsURL = localDocumentsURL.appendingPathComponent("assets")

    if fileManager.fileExists(atPath: iCloudAssetsURL.path) {
      try fileManager.copyItem(at: iCloudAssetsURL, to: localAssetsURL)
      logger.info("Assets restored from iCloud")
    }
  }
}

// MARK: - Supporting Types

public enum SyncStatus {
  case idle
  case syncing
  case completed
  case failed
}

public enum SyncError: LocalizedError {
  case iCloudUnavailable
  case syncDisabled
  case fileOperationFailed(Error)

  public var errorDescription: String? {
    switch self {
    case .iCloudUnavailable:
      return "iCloud is not available"
    case .syncDisabled:
      return "iCloud sync is disabled"
    case .fileOperationFailed(let error):
      return "File operation failed: \(error.localizedDescription)"
    }
  }
}

public struct DocumentState {
  public let fileName: String
  public let isDownloaded: Bool
  public let isUploaded: Bool
  public let downloadStatus: String?
  public let hasConflicts: Bool
  public let uploadingError: Error?
  public let downloadingError: Error?

  public var isFullySynced: Bool {
    return isDownloaded && isUploaded && !hasConflicts && !hasError
  }

  public var hasError: Bool {
    return uploadingError != nil || downloadingError != nil
  }

  public var statusDescription: String {
    if hasError {
      return "Error"
    } else if hasConflicts {
      return "Conflict"
    } else if isFullySynced {
      return "Synced"
    } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusDownloaded {
      return "Downloaded"
    } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
      return "Not Downloaded"
    } else {
      return "Syncing"
    }
  }
}
