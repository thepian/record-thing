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

  // Development
  @Published var isBackingUp: Bool = false
  @Published var isReloading: Bool = false

  // App Info
  @Published var appVersion: String = "1.0.0"
  @Published var buildNumber: String = "1"

  // MARK: - Private Properties

  private let userDefaults = UserDefaults(suiteName: "group.com.thepia.recordthing") ?? .standard
  private let keychain = KeychainManager()

  // MARK: - Initialization

  init() {
    loadAppInfo()
    loadSettings()
    setupSettingsObservers()
  }

  // MARK: - Settings Loading

  func loadSettings() {
    // Load account information
    accountName = userDefaults.string(forKey: "account_name") ?? "Demo User"
    accountEmail = userDefaults.string(forKey: "account_email") ?? "demo@thepia.com"

    // Load plan information
    if let planRawValue = userDefaults.string(forKey: "user_plan"),
      let plan = UserPlan(rawValue: planRawValue)
    {
      currentPlan = plan
    }

    // Load sync settings
    autoSyncEnabled = userDefaults.bool(forKey: "auto_sync_enabled")
    selectiveSyncEnabled = userDefaults.bool(forKey: "selective_sync_enabled")
    iCloudBackupEnabled = userDefaults.bool(forKey: "icloud_backup_enabled")

    // Load privacy settings
    contributeToAI =
      userDefaults.object(forKey: "contribute_to_ai") as? Bool ?? (currentPlan == .free)
    defaultPrivateRecordings = userDefaults.bool(forKey: "default_private_recordings")

    // Load demo mode
    demoModeEnabled = userDefaults.bool(forKey: "demo_mode_enabled")

    // Load last sync status
    if let lastSyncDate = userDefaults.object(forKey: "last_sync_date") as? Date {
      lastSyncStatus = RelativeDateTimeFormatter().localizedString(
        for: lastSyncDate, relativeTo: Date())
    }

    logger.info("Settings loaded successfully")
  }

  // MARK: - Settings Observers

  private func setupSettingsObservers() {
    // Auto-save settings when they change
    $autoSyncEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.userDefaults.set(value, forKey: "auto_sync_enabled")
        self?.logger.info("Auto sync setting changed: \(value)")
      }
      .store(in: &cancellables)

    $selectiveSyncEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.userDefaults.set(value, forKey: "selective_sync_enabled")
      }
      .store(in: &cancellables)

    $iCloudBackupEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.userDefaults.set(value, forKey: "icloud_backup_enabled")
      }
      .store(in: &cancellables)

    $contributeToAI
      .dropFirst()
      .sink { [weak self] value in
        self?.userDefaults.set(value, forKey: "contribute_to_ai")
      }
      .store(in: &cancellables)

    $defaultPrivateRecordings
      .dropFirst()
      .sink { [weak self] value in
        self?.userDefaults.set(value, forKey: "default_private_recordings")
      }
      .store(in: &cancellables)

    $demoModeEnabled
      .dropFirst()
      .sink { [weak self] value in
        self?.userDefaults.set(value, forKey: "demo_mode_enabled")
        self?.handleDemoModeChange(value)
      }
      .store(in: &cancellables)
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
      // Simulate sync operation
      try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

      // Update last sync status
      userDefaults.set(Date(), forKey: "last_sync_date")
      lastSyncStatus = "Just now"

      logger.info("Manual sync completed successfully")

    } catch {
      logger.error("Manual sync failed: \(error.localizedDescription)")
      lastSyncStatus = "Failed"
    }
  }

  // MARK: - Database Operations

  func triggerDatabaseBackup() async {
    isBackingUp = true
    defer { isBackingUp = false }

    do {
      // Simulate backup operation
      try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
      logger.info("Database backup completed")

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
