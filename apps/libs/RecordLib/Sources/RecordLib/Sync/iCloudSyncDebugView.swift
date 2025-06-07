//
//  iCloudSyncDebugView.swift
//  RecordLib
//
//  Created by Assistant on 07.06.2025.
//

import SwiftUI
import os

/// Debug view for monitoring and controlling iCloud sync functionality
public struct iCloudSyncDebugView: View {
  @StateObject private var syncManager = iCloudSyncManager.shared
  @State private var showingFileDetails = false
  @State private var selectedFile: String?
  @State private var showingLogs = false
  @State private var refreshTimer: Timer?

  private let logger = Logger(subsystem: "com.record-thing", category: "icloud-debug")

  public init() {}

  public var body: some View {
    NavigationView {
      List {
        // Status Section
        statusSection

        // Controls Section
        controlsSection

        // Statistics Section
        statisticsSection

        // Documents Section
        documentsSection

        // Debug Actions Section
        debugActionsSection
      }
      .navigationTitle("iCloud Sync Debug")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Refresh") {
            refreshData()
          }
        }
      }
      .onAppear {
        startAutoRefresh()
      }
      .onDisappear {
        stopAutoRefresh()
      }
      .sheet(isPresented: $showingFileDetails) {
        if let fileName = selectedFile,
          let documentState = syncManager.documentStates[fileName]
        {
          DocumentDetailView(fileName: fileName, state: documentState)
        }
      }
      .sheet(isPresented: $showingLogs) {
        SyncLogsView()
      }
    }
  }

  // MARK: - Status Section

  private var statusSection: some View {
    Section {
      HStack {
        Image(systemName: syncManager.isAvailable ? "icloud" : "icloud.slash")
          .foregroundColor(syncManager.isAvailable ? .blue : .red)
        VStack(alignment: .leading) {
          Text("iCloud Availability")
            .font(.headline)
          Text(syncManager.isAvailable ? "Available" : "Not Available")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Circle()
          .fill(syncManager.isAvailable ? Color.green : Color.red)
          .frame(width: 12, height: 12)
      }

      HStack {
        Image(systemName: syncManager.isEnabled ? "checkmark.circle" : "xmark.circle")
          .foregroundColor(syncManager.isEnabled ? .green : .orange)
        VStack(alignment: .leading) {
          Text("Sync Status")
            .font(.headline)
          Text(syncManager.isEnabled ? "Enabled" : "Disabled")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Text(syncStatusText)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(syncStatusColor.opacity(0.2))
          .foregroundColor(syncStatusColor)
          .cornerRadius(8)
      }

      if let lastSync = syncManager.lastSyncDate {
        HStack {
          Image(systemName: "clock")
            .foregroundColor(.blue)
          VStack(alignment: .leading) {
            Text("Last Sync")
              .font(.headline)
            Text(lastSync, style: .relative)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
        }
      }

      if syncManager.syncStatus == .syncing {
        HStack {
          ProgressView(value: syncManager.syncProgress)
            .progressViewStyle(LinearProgressViewStyle())
          Text("\(Int(syncManager.syncProgress * 100))%")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      if let error = syncManager.syncError {
        HStack {
          Image(systemName: "exclamationmark.triangle")
            .foregroundColor(.red)
          VStack(alignment: .leading) {
            Text("Sync Error")
              .font(.headline)
            Text(error.localizedDescription)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
        }
      }
    } header: {
      Text("Status")
    }
  }

  // MARK: - Controls Section

  private var controlsSection: some View {
    Section {
      if syncManager.isAvailable {
        Button(action: {
          if syncManager.isEnabled {
            syncManager.disableSync()
          } else {
            syncManager.enableSync()
          }
        }) {
          HStack {
            Image(systemName: syncManager.isEnabled ? "pause.circle" : "play.circle")
            Text(syncManager.isEnabled ? "Disable Sync" : "Enable Sync")
            Spacer()
          }
        }
        .foregroundColor(syncManager.isEnabled ? .red : .green)

        if syncManager.isEnabled {
          Button(action: {
            Task {
              await syncManager.performManualSync()
            }
          }) {
            HStack {
              Image(systemName: "arrow.triangle.2.circlepath")
              Text("Manual Sync")
              Spacer()
              if syncManager.syncStatus == .syncing {
                ProgressView()
                  .scaleEffect(0.8)
              }
            }
          }
          .disabled(syncManager.syncStatus == .syncing)
        }
      } else {
        Text("iCloud is not available. Check Settings > [Your Name] > iCloud")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    } header: {
      Text("Controls")
    }
  }

  // MARK: - Statistics Section

  private var statisticsSection: some View {
    Section {
      HStack {
        VStack {
          Text("\(syncManager.totalDocuments)")
            .font(.title2)
            .fontWeight(.bold)
          Text("Total")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)

        VStack {
          Text("\(syncManager.syncedDocuments)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.green)
          Text("Synced")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)

        VStack {
          Text("\(syncManager.pendingDocuments)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.orange)
          Text("Pending")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)

        VStack {
          Text("\(syncManager.errorDocuments)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.red)
          Text("Errors")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.vertical, 8)
    } header: {
      Text("Statistics")
    }
  }

  // MARK: - Documents Section

  private var documentsSection: some View {
    Section {
      if syncManager.documentStates.isEmpty {
        Text("No documents found")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        ForEach(Array(syncManager.documentStates.keys.sorted()), id: \.self) { fileName in
          if let state = syncManager.documentStates[fileName] {
            DocumentRowView(fileName: fileName, state: state) {
              selectedFile = fileName
              showingFileDetails = true
            }
          }
        }
      }
    } header: {
      Text("Documents (\(syncManager.documentStates.count))")
    }
  }

  // MARK: - Debug Actions Section

  private var debugActionsSection: some View {
    Section {
      Button("View Sync Logs") {
        showingLogs = true
      }

      Button("Force Refresh") {
        refreshData()
      }

      if syncManager.isAvailable {
        Button("Open iCloud Drive") {
          if let url = syncManager.iCloudContainerURL {
            #if os(macOS)
              NSWorkspace.shared.open(url)
            #else
              // On iOS, we can't directly open iCloud Drive to a specific folder
              logger.info("iCloud container URL: \(url)")
            #endif
          }
        }
      }
    } header: {
      Text("Debug Actions")
    }
  }

  // MARK: - Helper Properties

  private var syncStatusText: String {
    switch syncManager.syncStatus {
    case .idle:
      return "Idle"
    case .syncing:
      return "Syncing"
    case .completed:
      return "Completed"
    case .failed:
      return "Failed"
    }
  }

  private var syncStatusColor: Color {
    switch syncManager.syncStatus {
    case .idle:
      return .blue
    case .syncing:
      return .orange
    case .completed:
      return .green
    case .failed:
      return .red
    }
  }

  // MARK: - Helper Methods

  private func refreshData() {
    // Trigger a refresh of the sync manager state
    logger.info("Refreshing iCloud sync data")
  }

  private func startAutoRefresh() {
    refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
      refreshData()
    }
  }

  private func stopAutoRefresh() {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }
}

// MARK: - Document Row View

private struct DocumentRowView: View {
  let fileName: String
  let state: DocumentState
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: iconName)
          .foregroundColor(iconColor)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 2) {
          Text(fileName)
            .font(.body)
            .lineLimit(1)
          Text(state.statusDescription)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        if state.hasError {
          Image(systemName: "exclamationmark.triangle")
            .foregroundColor(.red)
        } else if state.hasConflicts {
          Image(systemName: "exclamationmark.triangle")
            .foregroundColor(.orange)
        } else if state.isFullySynced {
          Image(systemName: "checkmark.circle")
            .foregroundColor(.green)
        } else {
          ProgressView()
            .scaleEffect(0.8)
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var iconName: String {
    if fileName.hasSuffix(".sqlite") {
      return "cylinder"
    } else if fileName.hasPrefix("assets") {
      return "folder"
    } else {
      return "doc"
    }
  }

  private var iconColor: Color {
    if fileName.hasSuffix(".sqlite") {
      return .blue
    } else if fileName.hasPrefix("assets") {
      return .orange
    } else {
      return .gray
    }
  }
}

// MARK: - Preview

// MARK: - Document Detail View

private struct DocumentDetailView: View {
  let fileName: String
  let state: DocumentState
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        Section("File Information") {
          DetailRow(title: "Name", value: fileName)
          DetailRow(title: "Status", value: state.statusDescription)
          DetailRow(title: "Downloaded", value: state.isDownloaded ? "Yes" : "No")
          DetailRow(title: "Uploaded", value: state.isUploaded ? "Yes" : "No")
          DetailRow(title: "Has Conflicts", value: state.hasConflicts ? "Yes" : "No")
        }

        if let downloadStatus = state.downloadStatus {
          Section("Download Status") {
            DetailRow(title: "Status", value: downloadStatus)
          }
        }

        if let uploadError = state.uploadingError {
          Section("Upload Error") {
            Text(uploadError.localizedDescription)
              .foregroundColor(.red)
          }
        }

        if let downloadError = state.downloadingError {
          Section("Download Error") {
            Text(downloadError.localizedDescription)
              .foregroundColor(.red)
          }
        }
      }
      .navigationTitle("Document Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

private struct DetailRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
    }
  }
}

// MARK: - Sync Logs View

private struct SyncLogsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var logs: [String] = []

  var body: some View {
    NavigationView {
      List {
        if logs.isEmpty {
          Text("No sync logs available")
            .foregroundColor(.secondary)
        } else {
          ForEach(logs.indices, id: \.self) { index in
            Text(logs[index])
              .font(.system(.caption, design: .monospaced))
          }
        }
      }
      .navigationTitle("Sync Logs")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Clear") {
            logs.removeAll()
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .onAppear {
        loadLogs()
      }
    }
  }

  private func loadLogs() {
    // In a real implementation, this would load actual sync logs
    logs = [
      "2025-06-07 12:00:00 - iCloud sync started",
      "2025-06-07 12:00:01 - Checking iCloud availability",
      "2025-06-07 12:00:02 - iCloud container found",
      "2025-06-07 12:00:03 - Syncing database to iCloud",
      "2025-06-07 12:00:05 - Database sync completed",
      "2025-06-07 12:00:06 - Syncing assets to iCloud",
      "2025-06-07 12:00:10 - Assets sync completed",
      "2025-06-07 12:00:11 - Sync operation completed successfully",
    ]
  }
}

#if DEBUG
  struct iCloudSyncDebugView_Previews: PreviewProvider {
    static var previews: some View {
      iCloudSyncDebugView()
    }
  }
#endif
