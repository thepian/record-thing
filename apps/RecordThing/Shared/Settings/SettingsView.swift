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

  @State private var demoModeEnabled = false
  @State private var autoSyncEnabled = false
  @State private var contributeToAI = true
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
            Text("Demo User")
              .font(.headline)
            Text("demo@thepia.com")
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
              Text("Free Plan")
                .font(.headline)
              Spacer()
            }
            Text("Basic recording and local storage")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Button("Upgrade") {
            showingUpgradeSheet = true
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
        }
      } header: {
        Text("Plan & Billing")
      }

      Section {
        HStack {
          Label("iCloud Sync", systemImage: "icloud.and.arrow.up")
          Spacer()
          Toggle("", isOn: $autoSyncEnabled)
            .disabled(true)  // Disabled for free tier
        }

        Button("Sync Now") {
          // Manual sync
        }
        .disabled(true)

        NavigationLink("iCloud Debug") {
          SimpleiCloudDebugView()
        }

      } header: {
        Text("Sync & Backup")
      } footer: {
        Text("iCloud sync is available with Premium plan. Debug view shows sync status and logs.")
      }

      Section {
        HStack {
          Label("Contribute to AI Training", systemImage: "brain")
          Spacer()
          Toggle("", isOn: $contributeToAI)
            .disabled(true)  // Free tier always contributes
        }

        Button("Privacy Policy") {
          // Show privacy policy
        }

      } header: {
        Text("Privacy & Data")
      } footer: {
        Text("Free tier recordings help improve our AI. Upgrade to Premium for privacy controls.")
      }

      Section {
        HStack {
          Label("Demo Mode", systemImage: "play.circle")
          Spacer()
          Toggle("", isOn: $demoModeEnabled)
        }

        if demoModeEnabled {
          Button("Reset Demo Data") {
            // Reset demo data
          }
        }

      } header: {
        Text("Demo Mode")
      } footer: {
        if demoModeEnabled {
          Text("Demo mode limits database modifications and disables cloud sync.")
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

          Button("Backup Database") {
            AppDatasource.shared.triggerManualBackup()
          }

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
          Text("1.0.0")
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
        // Reset database
      }
    } message: {
      Text("This will permanently delete all your data and reset the app to its initial state.")
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

