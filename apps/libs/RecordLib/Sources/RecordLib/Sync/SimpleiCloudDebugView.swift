//
//  SimpleiCloudDebugView.swift
//  RecordLib
//
//  Created by Assistant on 07.06.2025.
//

import SwiftUI
import os

/// Simple debug view for monitoring automatic iCloud Documents syncing
public struct SimpleiCloudDebugView: View {
  @StateObject private var iCloudManager = SimpleiCloudManager.shared
  @State private var showingCreateFileSheet = false
  @State private var newFileName = ""
  @State private var newFileContent = ""
  @State private var documents: [URL] = []

  private let logger = Logger(subsystem: "com.record-thing", category: "icloud-debug")

  public init() {}

  public var body: some View {
    List {
      // Status Section
      statusSection

      // Controls Section
      controlsSection

      // Statistics Section
      statisticsSection

      // Documents Section
      documentsSection

      // Test Actions Section
      testActionsSection
    }
    .navigationTitle("iCloud Documents")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Refresh") {
          refreshDocuments()
        }
      }
    }
    .onAppear {
      refreshDocuments()
    }
    .sheet(isPresented: $showingCreateFileSheet) {
      CreateFileSheet(
        fileName: $newFileName,
        fileContent: $newFileContent,
        onCreate: createTestFile
      )
    }
  }

  // MARK: - Status Section

  private var statusSection: some View {
    Section {
      HStack {
        Image(systemName: iCloudManager.isAvailable ? "icloud" : "icloud.slash")
          .foregroundColor(iCloudManager.isAvailable ? .blue : .red)
        VStack(alignment: .leading) {
          Text("iCloud Documents")
            .font(.headline)
          Text(iCloudManager.isAvailable ? "Available" : "Not Available")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Circle()
          .fill(iCloudManager.isAvailable ? Color.green : Color.red)
          .frame(width: 12, height: 12)
      }

      HStack {
        Image(systemName: iCloudManager.isEnabled ? "checkmark.circle" : "xmark.circle")
          .foregroundColor(iCloudManager.isEnabled ? .green : .orange)
        VStack(alignment: .leading) {
          Text("Auto Sync")
            .font(.headline)
          Text(iCloudManager.isEnabled ? "Enabled" : "Disabled")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
      }

      HStack {
        Image(systemName: "folder")
          .foregroundColor(.blue)
        VStack(alignment: .leading) {
          Text("Documents Folder")
            .font(.headline)
          Text(iCloudManager.getDocumentsURL().path)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
        Spacer()
      }
    } header: {
      Text("Status")
    } footer: {
      Text("With proper entitlements, files in Documents folder sync automatically across devices.")
    }
  }

  // MARK: - Controls Section

  private var controlsSection: some View {
    Section {
      if iCloudManager.isAvailable {
        Button(action: {
          if iCloudManager.isEnabled {
            iCloudManager.disableSync()
          } else {
            iCloudManager.enableSync()
          }
        }) {
          HStack {
            Image(systemName: iCloudManager.isEnabled ? "pause.circle" : "play.circle")
            Text(iCloudManager.isEnabled ? "Disable Auto Sync" : "Enable Auto Sync")
            Spacer()
          }
        }
        .foregroundColor(iCloudManager.isEnabled ? .red : .green)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          Text("iCloud Not Available")
            .font(.headline)
            .foregroundColor(.red)

          Text("To enable iCloud Documents:")
            .font(.subheadline)

          Text("1. Check iOS Settings > [Your Name] > iCloud")
            .font(.caption)
          Text("2. Ensure iCloud Drive is enabled")
            .font(.caption)
          Text("3. Verify app has CloudDocuments entitlement")
            .font(.caption)
        }
        .padding(.vertical, 4)
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
          Text("\(iCloudManager.totalDocuments)")
            .font(.title2)
            .fontWeight(.bold)
          Text("Total")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)

        VStack {
          Text("\(iCloudManager.syncedDocuments)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.green)
          Text("Synced")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)

        VStack {
          Text("\(iCloudManager.pendingDocuments)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.orange)
          Text("Pending")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.vertical, 8)

      if iCloudManager.totalDocuments > 0 {
        Text(iCloudManager.getSyncSummary())
          .font(.caption)
          .foregroundColor(.secondary)
      }
    } header: {
      Text("Sync Statistics")
    }
  }

  // MARK: - Documents Section

  private var documentsSection: some View {
    Section {
      if documents.isEmpty {
        Text("No documents found")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        ForEach(documents, id: \.path) { document in
          DocumentRowView(
            document: document,
            syncStatus: iCloudManager.getFileStatus(document.lastPathComponent)
          )
        }
      }
    } header: {
      Text("Documents (\(documents.count))")
    }
  }

  // MARK: - Test Actions Section

  private var testActionsSection: some View {
    Section {
      Button("Create Test File") {
        showingCreateFileSheet = true
      }

      Button("Refresh Documents") {
        refreshDocuments()
      }

      if iCloudManager.isAvailable {
        Button("Open Documents Folder") {
          #if os(macOS)
            NSWorkspace.shared.open(iCloudManager.getDocumentsURL())
          #else
            logger.info("Documents folder: \(iCloudManager.getDocumentsURL().path)")
          #endif
        }
      }
    } header: {
      Text("Test Actions")
    }
  }

  // MARK: - Helper Methods

  private func refreshDocuments() {
    do {
      documents = try iCloudManager.getAllDocuments()
      logger.info("Refreshed documents list: \(documents.count) files")
    } catch {
      logger.error("Failed to refresh documents: \(error)")
      documents = []
    }
  }

  private func createTestFile() {
    guard !newFileName.isEmpty else { return }

    do {
      let _ = try iCloudManager.createTextFile(
        named: newFileName.hasSuffix(".txt") ? newFileName : "\(newFileName).txt",
        content: newFileContent.isEmpty ? "Test file created at \(Date())" : newFileContent
      )

      // Reset form
      newFileName = ""
      newFileContent = ""
      showingCreateFileSheet = false

      // Refresh documents list
      refreshDocuments()

      logger.info("Created test file: \(newFileName)")
    } catch {
      logger.error("Failed to create test file: \(error)")
    }
  }
}

// MARK: - Document Row View

private struct DocumentRowView: View {
  let document: URL
  let syncStatus: String

  var body: some View {
    HStack {
      Image(systemName: iconName)
        .foregroundColor(iconColor)
        .frame(width: 20)

      VStack(alignment: .leading, spacing: 2) {
        Text(document.lastPathComponent)
          .font(.body)
          .lineLimit(1)
        Text(syncStatus)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      statusIcon
    }
  }

  private var iconName: String {
    let pathExtension = document.pathExtension.lowercased()
    switch pathExtension {
    case "txt", "md":
      return "doc.text"
    case "sqlite", "db":
      return "cylinder"
    case "jpg", "jpeg", "png", "gif":
      return "photo"
    case "mp4", "mov":
      return "video"
    case "mp3", "m4a", "wav":
      return "music.note"
    default:
      return "doc"
    }
  }

  private var iconColor: Color {
    switch syncStatus {
    case "Synced":
      return .green
    case "Error":
      return .red
    case "Conflict":
      return .orange
    default:
      return .blue
    }
  }

  private var statusIcon: some View {
    Group {
      switch syncStatus {
      case "Synced":
        Image(systemName: "checkmark.circle")
          .foregroundColor(.green)
      case "Error":
        Image(systemName: "exclamationmark.triangle")
          .foregroundColor(.red)
      case "Conflict":
        Image(systemName: "exclamationmark.triangle")
          .foregroundColor(.orange)
      default:
        ProgressView()
          .scaleEffect(0.8)
      }
    }
  }
}

// MARK: - Create File Sheet

private struct CreateFileSheet: View {
  @Binding var fileName: String
  @Binding var fileContent: String
  let onCreate: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section("File Details") {
          TextField("File Name", text: $fileName)
          TextField("Content (optional)", text: $fileContent, axis: .vertical)
            .lineLimit(3...6)
        }
      }
      .navigationTitle("Create Test File")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Create") {
            onCreate()
          }
          .disabled(fileName.isEmpty)
        }
      }
    }
  }
}

#if DEBUG
  struct SimpleiCloudDebugView_Previews: PreviewProvider {
    static var previews: some View {
      SimpleiCloudDebugView()
    }
  }
#endif
