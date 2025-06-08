//
//  SettingsManager.swift
//  RecordThing
//
//  Created by AI Assistant on 07.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Combine
import Foundation
import RecordLib
import SwiftUI
import os

/// Manages app settings and user preferences
/// Handles freemium tier features and database operations
@MainActor
class SettingsManager: ObservableObject {
  private let logger = Logger(subsystem: "com.thepia.recordthing", category: "SettingsManager")

  // MARK: - Published Properties

  // Account Information
  @Published var accountName: String = "Demo User"
  @Published var accountEmail: String = "demo@thepia.com"
  @Published var currentPlan: UserPlan = .free

  // Sync Settings
  @Published var autoSyncEnabled: Bool = false
  @Published var selectiveSyncEnabled: Bool = false
  @Published var iCloudBackupEnabled: Bool = false
  @Published var isSyncing: Bool = false
  @Published var lastSyncStatus: String = "Never"

  // Privacy Settings
  @Published var contributeToAI: Bool = true
  @Published var defaultPrivateRecordings: Bool = false

  // Demo Mode
  @Published var demoModeEnabled: Bool = false
  @Published var isResettingDemo: Bool = false
  @Published var isUpdatingDemo: Bool = false

  // Development
  @Published var isBackingUp: Bool = false
  @Published var isReloading: Bool = false

  // App Info
  @Published var appVersion: String = "1.0.0"
  @Published var buildNumber: String = "1"

  // MARK: - Private Properties

  // Hybrid storage approach as per PRD
  private let appGroupDefaults =
    UserDefaults(suiteName: "group.com.thepia.recordthing") ?? .standard
  private let iCloudStore = NSUbiquitousKeyValueStore.default
  private let keychain = KeychainManager()

  // Device identifier for tracking settings changes
  private let deviceIDFV = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"

  // Read-only property for sync testing
  var settingsChanged: String {
    return iCloudStore.string(forKey: "settings_changed") ?? ""
  }

  // MARK: - Initialization

  init() {
    loadAppInfo()
    loadSettings()
    setupSettingsObservers()
  }

  // MARK: - Settings Loading

  func loadSettings() {
    // Load account information from iCloud (syncs across devices)
    accountName = iCloudStore.string(forKey: "account_name") ?? "Demo User"
    accountEmail = iCloudStore.string(forKey: "account_email") ?? "demo@thepia.com"

    // Load plan information from iCloud (syncs across devices)
    if let planRawValue = iCloudStore.string(forKey: "user_plan"),
      let plan = UserPlan(rawValue: planRawValue)
    {
      currentPlan = plan
    }

    // Load sync settings from iCloud (syncs across devices)
    autoSyncEnabled = iCloudStore.bool(forKey: "auto_sync_enabled")
    selectiveSyncEnabled = iCloudStore.bool(forKey: "selective_sync_enabled")
    iCloudBackupEnabled = iCloudStore.bool(forKey: "icloud_backup_enabled")

    // Load privacy settings from iCloud (syncs across devices)
    contributeToAI =
      iCloudStore.object(forKey: "contribute_to_ai") as? Bool ?? (currentPlan == .free)
    defaultPrivateRecordings = iCloudStore.bool(forKey: "default_private_recordings")

    // Load last sync status from iCloud (syncs across devices)
    if let lastSyncDate = iCloudStore.object(forKey: "last_sync_date") as? Date {
      lastSyncStatus = RelativeDateTimeFormatter().localizedString(
        for: lastSyncDate, relativeTo: Date())
    }

    // Load demo mode from App Group (local per device)
    demoModeEnabled = appGroupDefaults.bool(forKey: "rt.demo_mode_enabled")

    logger.info("Settings loaded successfully")
  }

  // MARK: - Settings Observers

  private func setupSettingsObservers() {
    // iCloud-synced settings (sync across devices)
    $autoSyncEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "auto_sync_enabled")
        self?.updateSettingsChanged()
        self?.logger.info("Auto sync setting changed: \(value)")
      }
      .store(in: &cancellables)

    $selectiveSyncEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "selective_sync_enabled")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    $iCloudBackupEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "icloud_backup_enabled")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    $contributeToAI
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "contribute_to_ai")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    $defaultPrivateRecordings
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "default_private_recordings")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    $currentPlan
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value.rawValue, forKey: "user_plan")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    $accountName
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "account_name")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    $accountEmail
      .dropFirst()
      .sink { [weak self] value in
        self?.iCloudStore.set(value, forKey: "account_email")
        self?.updateSettingsChanged()
      }
      .store(in: &cancellables)

    // App Group settings (local per device)
    $demoModeEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.appGroupDefaults.set(value, forKey: "rt.demo_mode_enabled")
        self?.handleDemoModeChange(value)
      }
      .store(in: &cancellables)
  }

  // Update settings changed tracker whenever iCloud settings change
  private func updateSettingsChanged() {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let changeRecord = "\(deviceIDFV):\(timestamp)"
    iCloudStore.set(changeRecord, forKey: "settings_changed")
    iCloudStore.synchronize()
  }

  private var cancellables = Set<AnyCancellable>()

  // MARK: - App Info

  private func loadAppInfo() {
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      appVersion = version
    }

    if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
      buildNumber = build
    }
  }

  // MARK: - Sync Operations

  func triggerManualSync() async {
    guard currentPlan == .premium else {
      logger.warning("Manual sync attempted on free tier")
      return
    }

    isSyncing = true
    defer { isSyncing = false }

    do {
      // Use the comprehensive iCloud sync manager for premium users
      await iCloudSyncManager.shared.performManualSync()

      // Update last sync status
      iCloudStore.set(Date(), forKey: "last_sync_date")
      lastSyncStatus = "Just now"

      logger.info("Manual sync completed successfully")

    } catch {
      logger.error("Manual sync failed: \(error.localizedDescription)")
      lastSyncStatus = "Failed"
    }
  }

  /// Trigger iCloud Documents folder sync (available for all users)
  func triggeriCloudDocumentsSync() async {
    guard SimpleiCloudManager.shared.isAvailable else {
      logger.warning("iCloud Documents sync attempted but iCloud not available")
      return
    }

    isSyncing = true
    defer { isSyncing = false }

    do {
      let manager = SimpleiCloudManager.shared

      // Enable sync if not already enabled
      if !manager.isEnabled {
        manager.enableSync()
      }

      // Force refresh metadata query to check sync status
      await refreshiCloudDocumentsStatus()

      // Update last sync status
      iCloudStore.set(Date(), forKey: "last_sync_date")
      lastSyncStatus = "Just now"

      logger.info("iCloud Documents sync triggered successfully")

    } catch {
      logger.error("iCloud Documents sync failed: \(error.localizedDescription)")
      lastSyncStatus = "Failed"
    }
  }

  /// Refresh iCloud Documents sync status
  private func refreshiCloudDocumentsStatus() async {
    // This will trigger the metadata query to refresh
    // The SimpleiCloudManager will automatically update its published properties
    logger.info("Refreshing iCloud Documents sync status...")

    // Give the system a moment to process
    try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
  }

  // MARK: - Database Operations

  func triggerDatabaseBackup() async {
    isBackingUp = true
    defer { isBackingUp = false }

    do {
      // Fast database backup using file system copy
      let fileManager = FileManager.default

      // Get App Support and Documents directories
      guard
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
          .first,
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
      else {
        logger.error("Could not access required directories")
        return
      }

      let sourceDBURL = appSupportURL.appendingPathComponent("database.sqlite")
      let backupDBURL = documentsURL.appendingPathComponent("database_backup.sqlite")

      // Remove existing backup if it exists
      if fileManager.fileExists(atPath: backupDBURL.path) {
        try fileManager.removeItem(at: backupDBURL)
      }

      // Copy database from App Support to Documents
      #if os(macOS)
        // On macOS, use copyfile for fast copying
        try fileManager.copyItem(at: sourceDBURL, to: backupDBURL)
      #else
        // On iOS, use standard file copy (APFS Copy-on-Write is automatic)
        try fileManager.copyItem(at: sourceDBURL, to: backupDBURL)
      #endif

      logger.info("Database backup completed successfully")

    } catch {
      logger.error("Database backup failed: \(error.localizedDescription)")
    }
  }

  func reloadDatabase() async {
    isReloading = true
    defer { isReloading = false }

    do {
      // Simulate reload operation
      try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
      logger.info("Database reload completed")

    } catch {
      logger.error("Database reload failed: \(error.localizedDescription)")
    }
  }

  func resetDatabase() async {
    do {
      // Simulate database reset
      try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
      logger.info("Database reset completed")

      // Reset settings to defaults
      resetToDefaults()

    } catch {
      logger.error("Database reset failed: \(error.localizedDescription)")
    }
  }

  // MARK: - Demo Mode Operations

  func resetDemoData() async {
    isResettingDemo = true
    defer { isResettingDemo = false }

    do {
      // Simulate demo data reset
      try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
      logger.info("Demo data reset completed")

    } catch {
      logger.error("Demo data reset failed: \(error.localizedDescription)")
    }
  }

  func updateDemoData() async {
    isUpdatingDemo = true
    defer { isUpdatingDemo = false }

    do {
      logger.info("Starting demo data update...")

      // Step 1: Download the latest demo database (placeholder)
      let latestDemoDB = try await downloadLatestDemoDatabase()

      // Step 2: Read the demo database (fallback to bundled if download fails)
      let demoDatabaseURL = latestDemoDB ?? getBundledDemoDatabase()
      guard let demoData = try await readDemoDatabase(from: demoDatabaseURL) else {
        logger.error("Failed to read demo database")
        return
      }

      // Step 3: Replace data in existing database with demo data
      try await replaceDemoDataInCurrentDatabase(with: demoData)

      logger.info("Demo data update completed successfully")

    } catch {
      logger.error("Demo data update failed: \(error.localizedDescription)")
    }
  }

  // MARK: - Demo Data Update Helper Methods

  private func downloadLatestDemoDatabase() async throws -> URL? {
    // Placeholder: Download latest demo database from cloud storage
    logger.info("Attempting to download latest demo database...")

    // Simulate network delay
    try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    // For now, return nil to fallback to bundled database
    logger.info("Download not implemented yet, falling back to bundled database")
    return nil
  }

  private func getBundledDemoDatabase() -> URL? {
    // Get the demo database from the app bundle
    guard let bundleURL = Bundle.main.url(forResource: "demo_database", withExtension: "sqlite")
    else {
      logger.error("Could not find bundled demo database")
      return nil
    }
    logger.info("Using bundled demo database")
    return bundleURL
  }

  private func readDemoDatabase(from url: URL) async throws -> [String: Any]? {
    // Placeholder: Read demo database and extract relevant data
    logger.info("Reading demo database from: \(url.path)")

    // Simulate database reading
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

    // Return placeholder demo data structure
    return [
      "things": [],
      "evidence": [],
      "strategists": [],
      "metadata": [
        "version": "1.0",
        "updated": Date(),
      ],
    ]
  }

  private func replaceDemoDataInCurrentDatabase(with demoData: [String: Any]) async throws {
    // Placeholder: Replace specific tables/data in current database with demo data
    logger.info("Replacing demo data in current database...")

    // Simulate database operations
    try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    // This would involve:
    // 1. Opening current database
    // 2. Backing up current user data (if any)
    // 3. Clearing demo-specific tables
    // 4. Inserting new demo data
    // 5. Updating metadata to mark as demo data

    logger.info("Demo data replacement completed")
  }

  private func handleDemoModeChange(_ enabled: Bool) {
    if enabled {
      // Disable sync when entering demo mode
      autoSyncEnabled = false
      logger.info("Demo mode enabled - sync disabled")
    } else {
      logger.info("Demo mode disabled")
    }
  }

  // MARK: - Helper Methods

  private func resetToDefaults() {
    accountName = "Demo User"
    accountEmail = "demo@thepia.com"
    currentPlan = .free
    autoSyncEnabled = false
    selectiveSyncEnabled = false
    iCloudBackupEnabled = false
    contributeToAI = true
    defaultPrivateRecordings = false
    demoModeEnabled = false
    lastSyncStatus = "Never"
  }
}

// MARK: - Supporting Types

enum UserPlan: String, CaseIterable {
  case free = "free"
  case premium = "premium"

  var displayName: String {
    switch self {
    case .free: return "Free"
    case .premium: return "Premium"
    }
  }

  var description: String {
    switch self {
    case .free: return "Basic recording and local storage"
    case .premium: return "Advanced features with cloud sync"
    }
  }
}

// MARK: - Keychain Manager

private class KeychainManager {
  // Placeholder for keychain operations
  func store(key: String, value: String) {
    // Implementation for keychain storage
  }

  func retrieve(key: String) -> String? {
    // Implementation for keychain retrieval
    return nil
  }
}
