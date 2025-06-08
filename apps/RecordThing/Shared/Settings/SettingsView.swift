//
//  SettingsView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 08.06.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import AVFoundation
import Blackbird
import RecordLib
import SwiftUI

// MARK: - Improved Settings View

struct ImprovedSettingsView: View {
  let captureService: CaptureService?
  let designSystem: DesignSystemSetup?

  // @StateObject private var settingsManager = SettingsManager()
  @State private var settingsManager = MockSettingsManager()
  @State private var showingUpgradeSheet = false
  @State private var showingDatabaseResetAlert = false

  init(captureService: CaptureService? = nil, designSystem: DesignSystemSetup? = nil) {
    self.captureService = captureService
    self.designSystem = designSystem
  }

  var body: some View {
    List {
      Section {
        HStack {
          Image(systemName: "person.circle.fill")
            .font(.title2)
            .foregroundColor(.accentColor)

          VStack(alignment: .leading) {
            Text(settingsManager.accountName)
              .font(.headline)
            Text(settingsManager.accountEmail)
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          Button("Edit") {
            // Edit account
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
      } header: {
        Text("Account")
      }

      Section {
        HStack {
          VStack(alignment: .leading) {
            HStack {
              Text(settingsManager.currentPlan.displayName)
                .font(.headline)

              if settingsManager.currentPlan == .premium {
                Image(systemName: "crown.fill")
                  .foregroundColor(.yellow)
                  .font(.caption)
              }

              Spacer()
            }
            Text(settingsManager.currentPlan.description)
              .font(.caption)
              .foregroundColor(.secondary)
          }

          if settingsManager.currentPlan == .free {
            Button("Upgrade") {
              showingUpgradeSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
          } else {
            Text("Active")
              .font(.caption)
              .foregroundColor(.green)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.green.opacity(0.1))
              .clipShape(Capsule())
          }
        }
      } header: {
        Text("Plan & Billing")
      }

      Section {
        // Auto Sync Toggle
        HStack {
          Label("Auto Sync", systemImage: "arrow.triangle.2.circlepath")
          Spacer()
          Toggle("", isOn: $settingsManager.autoSyncEnabled)
            .disabled(settingsManager.currentPlan == .free)
        }

        if settingsManager.currentPlan == .premium {
          // Selective Sync Toggle
          HStack {
            Label("Selective Sync", systemImage: "checkmark.circle")
            Spacer()
            Toggle("", isOn: $settingsManager.selectiveSyncEnabled)
          }

          // iCloud Backup Toggle
          HStack {
            Label("iCloud Backup", systemImage: "icloud")
            Spacer()
            Toggle("", isOn: $settingsManager.iCloudBackupEnabled)
          }
        }

        // iCloud Documents Sync (available for all users)
        Button(action: {
          Task {
            await settingsManager.triggeriCloudDocumentsSync()
          }
        }) {
          HStack {
            Label("Sync iCloud Documents", systemImage: "icloud.and.arrow.up")
            Spacer()
            if settingsManager.isSyncing {
              ProgressView()
                .controlSize(.small)
            }
          }
        }
        .disabled(settingsManager.isSyncing || !SimpleiCloudManager.shared.isAvailable)

        // Manual Sync Button (Premium only)
        Button(action: {
          Task {
            await settingsManager.triggerManualSync()
          }
        }) {
          HStack {
            Label("Sync Now", systemImage: "arrow.clockwise")
            Spacer()
            if settingsManager.isSyncing {
              ProgressView()
                .controlSize(.small)
            }
          }
        }
        .disabled(settingsManager.isSyncing || settingsManager.currentPlan == .free)

        // Last Sync Status
        HStack {
          Label("Last Sync", systemImage: "clock")
          Spacer()
          Text(settingsManager.lastSyncStatus)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        NavigationLink("iCloud Debug") {
          SimpleiCloudDebugView()
        }

      } header: {
        Text("Sync & Backup")
      } footer: {
        if settingsManager.currentPlan == .free {
          Text(
            "iCloud Documents sync is available for all users. Advanced sync features require Premium plan."
          )
        } else {
          Text(
            "Your data is automatically synced across all your devices with full Premium features.")
        }
      }

      Section {
        HStack {
          Label("Contribute to AI Training", systemImage: "brain")
          Spacer()
          Toggle("", isOn: $settingsManager.contributeToAI)
            .disabled(settingsManager.currentPlan == .free)  // Free tier always contributes
        }

        // Private Recordings (Premium only)
        if settingsManager.currentPlan == .premium {
          HStack {
            Label("Mark New Recordings Private", systemImage: "lock")
            Spacer()
            Toggle("", isOn: $settingsManager.defaultPrivateRecordings)
          }
        }

        Button("Privacy Policy") {
          // Show privacy policy
        }

      } header: {
        Text("Privacy & Data")
      } footer: {
        if settingsManager.currentPlan == .free {
          Text("Free tier recordings help improve our AI. Upgrade to Premium for privacy controls.")
        } else {
          Text("You have full control over your data privacy and AI training contributions.")
        }
      }

      Section {
        HStack {
          Label("Demo Mode", systemImage: "play.circle")
          Spacer()
          Toggle("", isOn: $settingsManager.demoModeEnabled)
        }

        if settingsManager.demoModeEnabled {
          Button(action: {
            Task {
              await settingsManager.resetDemoData()
            }
          }) {
            HStack {
              Label("Reset Demo Data", systemImage: "arrow.clockwise")
              Spacer()
              if settingsManager.isResettingDemo {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isResettingDemo)

          Button(action: {
            Task {
              await settingsManager.updateDemoData()
            }
          }) {
            HStack {
              Label("Update Demo Data", systemImage: "arrow.down.circle")
              Spacer()
              if settingsManager.isUpdatingDemo {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isUpdatingDemo)
        }

      } header: {
        Text("Demo Mode")
      } footer: {
        if settingsManager.demoModeEnabled {
          Text(
            "Demo mode limits database modifications and disables cloud sync to protect demo data.")
        } else {
          Text("Enable demo mode to explore the app with sample data.")
        }
      }

      #if DEBUG
        Section {
          // Database Controls
          NavigationLink("Database Debug") {
            DatabaseDebugView()
          }

          Button(action: {
            Task {
              await settingsManager.triggerDatabaseBackup()
            }
          }) {
            HStack {
              Label("Backup Database", systemImage: "externaldrive")
              Spacer()
              if settingsManager.isBackingUp {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isBackingUp)

          Button(action: {
            Task {
              await settingsManager.reloadDatabase()
            }
          }) {
            HStack {
              Label("Reload Database", systemImage: "arrow.clockwise")
              Spacer()
              if settingsManager.isReloading {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isReloading)

          Button("Reset Database") {
            showingDatabaseResetAlert = true
          }
          .foregroundColor(.red)

          // Camera Controls
          if let captureService = captureService, let designSystem = designSystem {
            Group {
              HStack {
                Text("Camera Stream")
                Spacer()
                CameraSwitcher(captureService: captureService, designSystem: designSystem)
              }

              HStack {
                Text("Power Mode")
                Spacer()
                CameraSubduedSwitcher(captureService: captureService, designSystem: designSystem)
              }

              VStack(alignment: .leading, spacing: 4) {
                Text("Capture Service Info")
                  .font(.headline)
                CaptureServiceInfo(captureService: captureService)
              }
            }
          }

        } header: {
          Text("Development")
        } footer: {
          Text("Development tools for debugging and testing. Camera controls moved from sidebar.")
        }
      #endif

      Section {
        HStack {
          Text("Version")
          Spacer()
          Text(settingsManager.appVersion)
            .foregroundColor(.secondary)
        }

        HStack {
          Text("Build")
          Spacer()
          Text(settingsManager.buildNumber)
            .foregroundColor(.secondary)
        }

        Button("Help & Support") {
          // Show help
        }
      } header: {
        Text("About")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle("Settings")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    .sheet(isPresented: $showingUpgradeSheet) {
      SimpleUpgradeView()
    }
    .alert("Reset Database", isPresented: $showingDatabaseResetAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        Task {
          await settingsManager.resetDatabase()
        }
      }
    } message: {
      Text(
        "This will permanently delete all your data and reset the app to its initial state. This action cannot be undone."
      )
    }
    .onAppear {
      settingsManager.loadSettings()
    }
  }
}

struct SimpleUpgradeView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Image(systemName: "crown.fill")
          .font(.system(size: 60))
          .foregroundColor(.yellow)

        Text("Upgrade to Premium")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Unlock advanced features and cloud sync")
          .font(.title3)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        Spacer()

        Button("Start Free Trial") {
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Text("$4.99/month after 7-day free trial")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Mock Settings Manager (Temporary)

class MockSettingsManager: ObservableObject {
  @Published var accountName: String = "Demo User"
  @Published var accountEmail: String = "demo@thepia.com"
  @Published var currentPlan: UserPlan = .free
  @Published var autoSyncEnabled: Bool = false
  @Published var selectiveSyncEnabled: Bool = false
  @Published var iCloudBackupEnabled: Bool = false
  @Published var isSyncing: Bool = false
  @Published var lastSyncStatus: String = "Never"
  @Published var contributeToAI: Bool = true
  @Published var defaultPrivateRecordings: Bool = false
  @Published var demoModeEnabled: Bool = false
  @Published var isResettingDemo: Bool = false
  @Published var isUpdatingDemo: Bool = false
  @Published var isBackingUp: Bool = false
  @Published var isReloading: Bool = false
  @Published var appVersion: String = "1.0.0"
  @Published var buildNumber: String = "1"

  func loadSettings() {
    // Mock implementation
  }

  func triggerManualSync() async {
    isSyncing = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    isSyncing = false
    lastSyncStatus = "Just now"
  }

  func triggeriCloudDocumentsSync() async {
    isSyncing = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    isSyncing = false
  }

  func resetDemoData() async {
    isResettingDemo = true
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    isResettingDemo = false
  }

  func updateDemoData() async {
    isUpdatingDemo = true
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    isUpdatingDemo = false
  }

  func triggerDatabaseBackup() async {
    isBackingUp = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    isBackingUp = false
  }

  func reloadDatabase() async {
    isReloading = true
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    isReloading = false
  }

  func resetDatabase() async {
    try? await Task.sleep(nanoseconds: 2_000_000_000)
  }
}

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

#if DEBUG
  struct ImprovedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
      ImprovedSettingsView(
        captureService: CaptureService(),
        designSystem: .light
      )
    }
  }
#endif
