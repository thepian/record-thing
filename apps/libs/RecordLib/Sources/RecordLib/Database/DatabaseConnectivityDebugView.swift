//
//  DatabaseConnectivityDebugView.swift
//  RecordLib
//
//  Created by AI Assistant on 08.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os

/// Enhanced database debugging view with macOS connectivity diagnostics
public struct DatabaseConnectivityDebugView: View {

  @StateObject private var connectivityManager = DatabaseConnectivityManager.shared
  @StateObject private var monitor = DatabaseMonitor.shared
  @EnvironmentObject private var datasource: AppDatasource

  @State private var isRunningDiagnostics = false
  @State private var selectedMode: DatabaseConnectivityManager.DatabaseMode = .production
  @State private var testConnectionResult: String?

  private let logger = Logger(subsystem: "com.record-thing", category: "connectivity-debug")

  public init() {}

  public var body: some View {
    List {
      // Connection Status Section
      connectionStatusSection

      // Database Mode Selection
      modeSelectionSection

      // Diagnostics Section
      diagnosticsSection

      // Connectivity Actions
      actionsSection

      // Detailed Information
      detailedInfoSection

      // Console Logs
      logsSection
    }
    .navigationTitle("Database Connectivity")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Run Diagnostics") {
          runComprehensiveDiagnostics()
        }
        .disabled(isRunningDiagnostics)
      }
    }
    .onAppear {
      Task {
        let _ = await connectivityManager.performDiagnostics()
      }
    }
  }

  // MARK: - Connection Status Section

  private var connectionStatusSection: some View {
    Section("Connection Status") {
      HStack {
        Circle()
          .fill(connectivityManager.isConnected ? .green : .red)
          .frame(width: 12, height: 12)

        Text("Database Connection")

        Spacer()

        Text(connectivityManager.isConnected ? "Connected" : "Disconnected")
          .fontWeight(.medium)
          .foregroundColor(connectivityManager.isConnected ? .green : .red)
      }

      HStack {
        Image(systemName: "gear")
          .foregroundColor(.blue)

        Text("Current Mode")

        Spacer()

        Text(connectivityManager.currentMode.displayName)
          .fontWeight(.medium)
          .foregroundColor(.blue)
      }

      if let diagnostics = connectivityManager.diagnostics {
        HStack {
          Image(
            systemName: diagnostics.issues.isEmpty ? "checkmark.circle" : "exclamationmark.triangle"
          )
          .foregroundColor(diagnostics.issues.isEmpty ? .green : .orange)

          Text("Issues Found")

          Spacer()

          Text("\(diagnostics.issues.count)")
            .fontWeight(.medium)
            .foregroundColor(diagnostics.issues.isEmpty ? .green : .orange)
        }
      }
    }
  }

  // MARK: - Mode Selection Section

  private var modeSelectionSection: some View {
    Section("Database Mode") {
      Picker("Mode", selection: $selectedMode) {
        Text("Production (App Support)").tag(DatabaseConnectivityManager.DatabaseMode.production)
        Text("Development (Git)").tag(DatabaseConnectivityManager.DatabaseMode.development)
        Text("Debug (Desktop)").tag(DatabaseConnectivityManager.DatabaseMode.debug)
        Text("In-Memory Clone").tag(DatabaseConnectivityManager.DatabaseMode.inMemory)
        Text("Bundled (Read-Only)").tag(DatabaseConnectivityManager.DatabaseMode.bundled)
      }
      .pickerStyle(.menu)

      Button("Test Connection") {
        testConnection(mode: selectedMode)
      }
      .disabled(isRunningDiagnostics)

      if let result = testConnectionResult {
        Text(result)
          .font(.caption)
          .foregroundColor(result.contains("✅") ? .green : .red)
      }
    }
  }

  // MARK: - Diagnostics Section

  private var diagnosticsSection: some View {
    Section("Diagnostics") {
      if let diagnostics = connectivityManager.diagnostics {
        DatabaseDiagnosticsRow(title: "Database Path", value: diagnostics.path)
        DatabaseDiagnosticsRow(
          title: "File Exists", value: diagnostics.exists ? "Yes" : "No",
          status: diagnostics.exists ? .success : .error)
        DatabaseDiagnosticsRow(
          title: "Readable", value: diagnostics.isReadable ? "Yes" : "No",
          status: diagnostics.isReadable ? .success : .error)
        DatabaseDiagnosticsRow(
          title: "Writable", value: diagnostics.isWritable ? "Yes" : "No",
          status: diagnostics.isWritable ? .success : .warning)

        if let fileSize = diagnostics.fileSize {
          DatabaseDiagnosticsRow(
            title: "File Size",
            value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
        }

        #if os(macOS)
          DatabaseDiagnosticsRow(
            title: "Quarantine Attributes",
            value: diagnostics.hasQuarantineAttributes ? "Present" : "None",
            status: diagnostics.hasQuarantineAttributes ? .error : .success)

          if let sandboxPath = diagnostics.sandboxPath {
            DatabaseDiagnosticsRow(title: "Sandbox Container", value: sandboxPath)
          }
        #endif

        if !diagnostics.issues.isEmpty {
          ForEach(Array(diagnostics.issues.enumerated()), id: \.offset) { index, issue in
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundColor(.orange)
                Text(issue.description)
                  .font(.caption)
                  .fontWeight(.medium)
              }

              Text(issue.recommendation)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 20)
            }
            .padding(.vertical, 2)
          }
        }
      } else {
        Text("No diagnostics available")
          .foregroundColor(.secondary)
      }
    }
  }

  // MARK: - Actions Section

  private var actionsSection: some View {
    Section("Actions") {
      Button("Run Full Diagnostics") {
        runComprehensiveDiagnostics()
      }
      .disabled(isRunningDiagnostics)

      Button("Attempt Fallback Connection") {
        attemptFallbackConnection()
      }
      .disabled(isRunningDiagnostics)

      #if os(macOS)
        Button("Remove Quarantine Attributes") {
          removeQuarantineAttributes()
        }
        .disabled(isRunningDiagnostics)
      #endif

      Button("Create In-Memory Clone") {
        createInMemoryClone()
      }
      .disabled(isRunningDiagnostics)

      Button("Reset to Bundled Database") {
        resetToBundledDatabase()
      }
      .foregroundColor(.red)
      .disabled(isRunningDiagnostics)
    }
  }

  // MARK: - Detailed Information Section

  private var detailedInfoSection: some View {
    Section("System Information") {
      #if os(macOS)
        DatabaseDiagnosticsRow(title: "Platform", value: "macOS")
        DatabaseDiagnosticsRow(title: "App Sandbox", value: "Enabled")

        if let bundleId = Bundle.main.bundleIdentifier {
          DatabaseDiagnosticsRow(title: "Bundle ID", value: bundleId)
        }

        let homeDir = NSHomeDirectory()
        DatabaseDiagnosticsRow(title: "Home Directory", value: homeDir)

        let containerPath =
          "\(homeDir)/Library/Containers/\(Bundle.main.bundleIdentifier ?? "unknown")/Data"
        DatabaseDiagnosticsRow(title: "Sandbox Container", value: containerPath)

        // Show actual App Support path being used
        let actualAppSupportPath = FileManager.default.urls(
          for: .applicationSupportDirectory, in: .userDomainMask)[0]
        DatabaseDiagnosticsRow(
          title: "Actual App Support", value: actualAppSupportPath.platformPath)

        // Show if the database file exists
        let dbPath = actualAppSupportPath.appendingPathComponent("record-thing.sqlite")
        let dbExists = FileManager.default.fileExists(atPath: dbPath.platformPath)
        DatabaseDiagnosticsRow(
          title: "Database File Exists",
          value: dbExists ? "Yes" : "No",
          status: dbExists ? .success : .error
        )
      #else
        DatabaseDiagnosticsRow(title: "Platform", value: "iOS")
      #endif

      let appSupportURL = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask)[0]
      DatabaseDiagnosticsRow(title: "App Support", value: appSupportURL.platformPath)

      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      DatabaseDiagnosticsRow(title: "Documents", value: documentsURL.platformPath)
    }
  }

  // MARK: - Logs Section

  private var logsSection: some View {
    Section("Console Logs") {
      NavigationLink("Show Detailed Logs", destination: DatabaseLogsView())

      if let lastError = connectivityManager.lastError {
        VStack(alignment: .leading, spacing: 4) {
          Text("Last Error:")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.red)

          Text(lastError.localizedDescription)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
  }

  // MARK: - Action Methods

  private func runComprehensiveDiagnostics() {
    isRunningDiagnostics = true
    logger.info("🔍 Running comprehensive database diagnostics")

    Task {
      let _ = await connectivityManager.performDiagnostics()

      await MainActor.run {
        isRunningDiagnostics = false
        logger.info("✅ Diagnostics completed")
      }
    }
  }

  private func testConnection(mode: DatabaseConnectivityManager.DatabaseMode) {
    isRunningDiagnostics = true
    testConnectionResult = nil

    Task {
      let database = await connectivityManager.attemptConnection(mode: mode)

      await MainActor.run {
        if database != nil {
          testConnectionResult = "✅ Connection successful"
        } else {
          testConnectionResult = "❌ Connection failed"
        }
        isRunningDiagnostics = false
      }
    }
  }

  private func attemptFallbackConnection() {
    isRunningDiagnostics = true

    Task {
      let (database, mode) = await connectivityManager.connectWithFallback()

      await MainActor.run {
        if let db = database {
          // Update datasource with new database
          datasource.updateDatabase(db, mode: mode)
          testConnectionResult = "✅ Fallback connection successful (\(mode.displayName))"
        } else {
          testConnectionResult = "❌ All fallback connections failed"
        }
        isRunningDiagnostics = false
      }
    }
  }

  #if os(macOS)
    private func removeQuarantineAttributes() {
      isRunningDiagnostics = true

      Task {
        guard
          let bundlePath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
        else {
          await MainActor.run {
            testConnectionResult = "❌ Bundled database not found"
            isRunningDiagnostics = false
          }
          return
        }

        let success = await connectivityManager.removeQuarantineAttributes(from: bundlePath)

        await MainActor.run {
          testConnectionResult =
            success ? "✅ Quarantine attributes removed" : "❌ Failed to remove quarantine attributes"
          isRunningDiagnostics = false
        }
      }
    }
  #endif

  private func createInMemoryClone() {
    isRunningDiagnostics = true

    Task {
      let database = await connectivityManager.createInMemoryClone()

      await MainActor.run {
        if let db = database {
          datasource.updateDatabase(db, mode: .inMemory)
          testConnectionResult = "✅ In-memory clone created successfully"
        } else {
          testConnectionResult = "❌ Failed to create in-memory clone"
        }
        isRunningDiagnostics = false
      }
    }
  }

  private func resetToBundledDatabase() {
    isRunningDiagnostics = true

    Task {
      datasource.resetDatabase()

      await MainActor.run {
        testConnectionResult = "✅ Database reset to bundled version"
        isRunningDiagnostics = false
      }
    }
  }
}

// MARK: - Helper Views

private struct DatabaseDiagnosticsRow: View {
  let title: String
  let value: String
  let status: Status?

  enum Status {
    case success, warning, error

    var color: Color {
      switch self {
      case .success: return .green
      case .warning: return .orange
      case .error: return .red
      }
    }

    var icon: String {
      switch self {
      case .success: return "checkmark.circle.fill"
      case .warning: return "exclamationmark.triangle.fill"
      case .error: return "xmark.circle.fill"
      }
    }
  }

  init(title: String, value: String, status: Status? = nil) {
    self.title = title
    self.value = value
    self.status = status
  }

  var body: some View {
    HStack {
      if let status = status {
        Image(systemName: status.icon)
          .foregroundColor(status.color)
          .frame(width: 16)
      }

      Text(title)
        .font(.caption)

      Spacer()

      Text(value)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.trailing)
    }
  }
}

private struct DatabaseLogsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var monitor = DatabaseMonitor.shared

  var body: some View {
    List {
      ForEach(Array(monitor.activities.reversed())) { activity in
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(activity.type.rawValue)
              .font(.caption)
              .fontWeight(.medium)

            Spacer()

            Text(activity.timestamp, style: .time)
              .font(.caption2)
              .foregroundColor(.secondary)
          }

          if let details = activity.details {
            Text(details)
              .font(.caption2)
              .foregroundColor(.secondary)
          }

          if let error = activity.error {
            Text("Error: \(error.localizedDescription)")
              .font(.caption2)
              .foregroundColor(.red)
          }
        }
        .padding(.vertical, 2)
      }
    }
    .navigationTitle("Database Logs")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Close") {
          dismiss()
        }
      }
    }
  }
}

// MARK: - Extensions

// displayName extension is defined in DatabaseConnectivityManager.swift

// MARK: - Preview

struct DatabaseConnectivityDebugView_Previews: PreviewProvider {
  static var previews: some View {
    DatabaseConnectivityDebugView()
      .environmentObject(AppDatasource.shared)
  }
}
