//
//  SettingsView.swift
//  RecordThing
//
//  Created by AI Assistant on 07.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import RecordLib
import SwiftUI

/// Comprehensive Settings view following iOS design patterns
/// Compatible with iPhone, iPad, and macOS - works within split view or standalone
struct SettingsView: View {
  @Environment(\.appDatasource) private var appDatasource
  @StateObject private var settingsManager = SettingsManager()
  @State private var showingUpgradeSheet = false
  @State private var showingPrivacyPolicy = false
  @State private var showingDatabaseResetAlert = false
  @State private var showingDemoResetAlert = false

  var body: some View {
    SettingsContent(
      settingsManager: settingsManager,
      showingUpgradeSheet: $showingUpgradeSheet,
      showingPrivacyPolicy: $showingPrivacyPolicy,
      showingDatabaseResetAlert: $showingDatabaseResetAlert,
      showingDemoResetAlert: $showingDemoResetAlert
    )
    .navigationTitle("Settings")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    #endif
    .sheet(isPresented: $showingUpgradeSheet) {
      UpgradeView()
    }
    .sheet(isPresented: $showingPrivacyPolicy) {
      PrivacyPolicyView()
    }
    .alert("Reset Database", isPresented: $showingDatabaseResetAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Reset", role: .destructive) {
        Task {
          await settingsManager.resetDatabase()
        }
      }
    } message: {
      Text("This will permanently delete all your data and reset the app to its initial state. This action cannot be undone.")
    }
    .alert("Reset Demo Data", isPresented: $showingDemoResetAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Reset", role: .destructive) {
        Task {
          await settingsManager.resetDemoData()
        }
      }
    } message: {
      Text("This will restore the demo data to its original state.")
    }
    .onAppear {
      settingsManager.loadSettings()
    }
  }
}

/// The actual settings content that can be used standalone or within navigation
struct SettingsContent: View {
  @ObservedObject var settingsManager: SettingsManager
  @Binding var showingUpgradeSheet: Bool
  @Binding var showingPrivacyPolicy: Bool
  @Binding var showingDatabaseResetAlert: Bool
  @Binding var showingDemoResetAlert: Bool

  var body: some View {
    List {
        // Account Section
        accountSection

        // Plan & Billing Section
        planSection

        // Sync & Backup Section
        syncSection

        // Privacy & Data Section
        privacySection

        // Demo Mode Section
        demoSection

        // Development Section (hidden in production)
        #if DEBUG
          developmentSection
        #endif

        // About Section
        aboutSection
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    #if os(macOS)
    .frame(minWidth: 300, idealWidth: 400, maxWidth: .infinity)
    #endif
  }
  }

  // MARK: - Account Section

  @ViewBuilder
  private var accountSection: some View {
    Section {
      HStack {
        Image(systemName: "person.circle.fill")
          .font(.title2)
          .foregroundColor(.accentColor)

        VStack(alignment: .leading, spacing: 2) {
          Text(settingsManager.accountName)
            .font(.headline)
          Text(settingsManager.accountEmail)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        Button("Edit") {
          // Navigate to account editing
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      .padding(.vertical, 4)
    } header: {
      Text("Account")
    }
  }

  // MARK: - Plan Section

  @ViewBuilder
  private var planSection: some View {
    Section {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(settingsManager.currentPlan.displayName)
              .font(.headline)

            if settingsManager.currentPlan == .premium {
              Image(systemName: "crown.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            }
          }

          Text(settingsManager.currentPlan.description)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

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
      .padding(.vertical, 4)

      if settingsManager.currentPlan == .premium {
        NavigationLink("Manage Subscription") {
          SubscriptionManagementView()
        }
      }
    } header: {
      Text("Plan & Billing")
    }
  }

  // MARK: - Sync Section

  @ViewBuilder
  private var syncSection: some View {
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

      // Manual Sync Button
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

    } header: {
      Text("Sync & Backup")
    } footer: {
      if settingsManager.currentPlan == .free {
        Text("Sync features are available with Premium plan.")
      } else {
        Text("Your data is automatically synced across all your devices.")
      }
    }
  }

  // MARK: - Privacy Section

  @ViewBuilder
  private var privacySection: some View {
    Section {
      // AI Training Contribution
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

      NavigationLink("Privacy Policy") {
        PrivacyPolicyView()
      }

      NavigationLink("Data Export") {
        DataExportView()
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
  }

  // MARK: - Demo Section

  @ViewBuilder
  private var demoSection: some View {
    Section {
      HStack {
        Label("Demo Mode", systemImage: "play.circle")
        Spacer()
        Toggle("", isOn: $settingsManager.demoModeEnabled)
      }

      if settingsManager.demoModeEnabled {
        Button(action: {
          showingDemoResetAlert = true
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
  }

  // MARK: - Development Section

  #if DEBUG
    @ViewBuilder
    private var developmentSection: some View {
      Section {
        // Database Management
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

        Button(action: {
          showingDatabaseResetAlert = true
        }) {
          HStack {
            Label("Reset Database", systemImage: "trash")
              .foregroundColor(.red)
            Spacer()
          }
        }

        // ShareExtension Debug
        NavigationLink("ShareExtension Debug") {
          ShareExtensionDebugView()
        }

        // Database Error Dashboard
        NavigationLink("Error Dashboard") {
          DatabaseErrorDashboard()
        }

      } header: {
        Text("Development")
      } footer: {
        Text("Development tools for debugging and testing. Hidden in production builds.")
      }
    }
  #endif

  // MARK: - About Section

  @ViewBuilder
  private var aboutSection: some View {
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

      NavigationLink("Help & Support") {
        HelpSupportView()
      }

      NavigationLink("What's New") {
        WhatsNewView()
      }

      Link("Rate on App Store", destination: URL(string: "https://apps.apple.com/app/recordthing")!)

    } header: {
      Text("About")
    }
  }
}
