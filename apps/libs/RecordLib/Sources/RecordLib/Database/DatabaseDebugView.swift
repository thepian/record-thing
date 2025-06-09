//
//  DatabaseDebugView.swift
//  RecordLib
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os

/// Simple database debug view for RecordLib
public struct DatabaseDebugView: View {
  @Environment(\.appDatasource) private var datasource
  @StateObject private var monitor = DatabaseMonitor.shared

  @State private var isPerformingAction = false
  @State private var lastActionResult: String?
  @State private var showingErrorDetails = false

  private let logger = Logger(subsystem: "com.record-thing", category: "debug-menu")

  public init() {}

  public var body: some View {
    List {
      // Status Section
      Section("Database Status") {
        HStack {
          Circle()
            .fill(monitor.currentStatus.color)
            .frame(width: 12, height: 12)

          Text("Status")

          Spacer()

          Text(monitor.currentStatus.displayName)
            .fontWeight(.medium)
            .foregroundColor(monitor.currentStatus.color)
        }

        HStack {
          Image(
            systemName: monitor.isHealthy
              ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
          )
          .foregroundColor(monitor.isHealthy ? .green : .red)

          Text("Health")

          Spacer()

          Text(monitor.isHealthy ? "Healthy" : "Issues")
            .fontWeight(.medium)
            .foregroundColor(monitor.isHealthy ? .green : .red)
        }

        if let connectionInfo = monitor.connectionInfo {
          HStack {
            Image(systemName: "cylinder.fill")
              .foregroundColor(.blue)

            Text("Database Type")

            Spacer()

            Text(connectionInfo.type.displayName)
              .fontWeight(.medium)
          }

          HStack {
            Image(systemName: "folder.fill")
              .foregroundColor(.orange)

            Text("Path")

            Spacer()

            Text(connectionInfo.path.split(separator: "/").last.map(String.init) ?? "Unknown")
              .fontWeight(.medium)
              .lineLimit(1)
          }
        }
      }

      // Statistics Section
      Section("Statistics") {
        let stats = monitor.getStatistics()

        StatisticRow(
          title: "Total Activities", value: "\(stats.totalActivities)", icon: "list.bullet")
        Button(action: {
          showingErrorDetails = true
        }) {
          StatisticRow(
            title: "Errors", value: "\(stats.errorCount)", icon: "exclamationmark.triangle",
            color: stats.errorCount > 0 ? .red : .green)
        }
        .buttonStyle(.plain)
        .disabled(stats.errorCount == 0)
        StatisticRow(
          title: "Connections", value: "\(stats.connectionCount)", icon: "link", color: .blue)
        StatisticRow(
          title: "Queries", value: "\(stats.queryCount)", icon: "magnifyingglass", color: .purple)

        if let uptime = stats.formattedUptime {
          StatisticRow(title: "Uptime", value: uptime, icon: "clock", color: .green)
        }

        StatisticRow(
          title: "Error Rate",
          value: String(format: "%.1f%%", stats.errorRate * 100),
          icon: "percent",
          color: stats.errorRate > 0.1 ? .red : .green
        )
      }

      // Actions Section
      Section("Database Actions") {
        DatabaseActionButton(
          title: "Reload Database",
          subtitle: "Reconnect to the current database",
          icon: "arrow.clockwise",
          color: .blue,
          isPerforming: isPerformingAction
        ) {
          performAction("Reload") {
            datasource?.reloadDatabase()
          }
        }

        DatabaseActionButton(
          title: "Reset Database",
          subtitle: "Reset to default bundled database",
          icon: "trash",
          color: .red,
          isPerforming: isPerformingAction
        ) {
          performAction("Reset") {
            datasource?.resetDatabase()
          }
        }

        DatabaseActionButton(
          title: "Update Database",
          subtitle: "Update translations from bundle",
          icon: "square.and.arrow.down",
          color: .orange,
          isPerforming: isPerformingAction
        ) {
          performAction("Update") {
            Task {
              await datasource?.updateDatabase()
            }
          }
        }

        #if os(macOS)
          // macOS-specific action to copy development database
          if FileManager.default.fileExists(
            atPath: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
          ) {
            DatabaseActionButton(
              title: "Copy Development Database",
              subtitle: "Overwrite App Support DB with development DB",
              icon: "doc.on.doc",
              color: .purple,
              isPerforming: isPerformingAction
            ) {
              performAction("Copy Development DB") {
                copyDevelopmentDatabase()
              }
            }
          }
        #endif
      }

      // File System Section
      Section("Database Files") {
        Button(action: {
          openAppSupportFolder()
        }) {
          HStack {
            Image(systemName: "folder")
              .foregroundColor(.blue)
              .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
              Text("Open App Support Folder")
                .fontWeight(.medium)

              Text("View database files in Finder")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "arrow.up.right.square")
              .foregroundColor(.blue)
              .font(.caption)
          }
        }
        .buttonStyle(.plain)
      }

      // Monitoring Section
      Section("Monitoring") {
        DatabaseActionButton(
          title: "Health Check",
          subtitle: "Perform database connectivity test",
          icon: "stethoscope",
          color: .green,
          isPerforming: isPerformingAction
        ) {
          performAction("Health Check") {
            monitor.checkHealth()
          }
        }

        NavigationLink(destination: ConnectivityDebugWrapper(datasource: datasource)) {
          HStack {
            Image(systemName: "network")
              .foregroundColor(.orange)
              .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
              Text("Connectivity Debug")
                .fontWeight(.medium)

              Text("macOS database connection diagnostics")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
          }
        }
      }

      // Recent Activities Preview
      if !monitor.activities.isEmpty {
        Section("Recent Activities") {
          ForEach(Array(monitor.activities.prefix(5))) { activity in
            HStack(spacing: 8) {
              Image(systemName: activity.statusIcon)
                .foregroundColor(activity.statusColor)
                .frame(width: 16)

              VStack(alignment: .leading, spacing: 2) {
                Text(activity.type.rawValue)
                  .font(.subheadline)
                  .fontWeight(.medium)

                if let details = activity.details {
                  Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                }

                if let error = activity.error {
                  Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(1)
                }
              }

              Spacer()

              Text(activity.formattedTimestamp)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
          }
        }
      }

      // Action Result
      if let result = lastActionResult {
        Section("Last Action") {
          HStack {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)

            Text(result)
              .fontWeight(.medium)

            Spacer()
          }
        }
      }
    }
    .navigationTitle("Database Debug")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .refreshable {
      monitor.checkHealth()
    }
    .sheet(isPresented: $showingErrorDetails) {
      DatabaseErrorDetailsView()
    }
  }

  // MARK: - Helper Methods

  private func performAction(_ actionName: String, action: @escaping () -> Void) {
    guard !isPerformingAction else { return }

    isPerformingAction = true
    lastActionResult = nil

    logger.info("Performing database action: \(actionName)")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      action()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isPerformingAction = false
        lastActionResult = "\(actionName) completed"

        // Clear result after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          lastActionResult = nil
        }
      }
    }
  }

  #if os(macOS)
    private func copyDevelopmentDatabase() {
      let testPath =
        "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite"
      let appSupportPath = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("record-thing.sqlite")

      do {
        // Close current database connection
        Task {
          await datasource?.db?.close()
        }

        // Remove existing database
        if FileManager.default.fileExists(atPath: appSupportPath.path) {
          try FileManager.default.removeItem(at: appSupportPath)
        }

        // Copy development database
        try FileManager.default.copyItem(
          atPath: testPath,
          toPath: appSupportPath.path
        )

        logger.info("✅ Successfully copied development database to App Support")

        // Reload database
        DispatchQueue.main.async {
          self.datasource?.reloadDatabase()
        }

      } catch {
        logger.error("❌ Failed to copy development database: \(error)")
      }
    }
  #endif

  private func openAppSupportFolder() {
    let appSupportPath = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0]

    #if os(macOS)
      NSWorkspace.shared.open(appSupportPath)
    #endif
  }
}

// MARK: - Supporting Views

struct StatisticRow: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  init(title: String, value: String, icon: String, color: Color = .primary) {
    self.title = title
    self.value = value
    self.icon = icon
    self.color = color
  }

  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(color)
        .frame(width: 24)

      Text(title)

      Spacer()

      Text(value)
        .fontWeight(.medium)
        .foregroundColor(color)
    }
  }
}

struct DatabaseActionButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
  let isPerforming: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        if isPerforming {
          ProgressView()
            .scaleEffect(0.8)
            .frame(width: 24)
        } else {
          Image(systemName: icon)
            .foregroundColor(color)
            .frame(width: 24)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .fontWeight(.medium)

          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()
      }
    }
    .buttonStyle(.plain)
    .disabled(isPerforming)
  }
}

// MARK: - Helper Views

private struct DatabaseErrorDetailsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var monitor = DatabaseMonitor.shared

  var body: some View {
    NavigationView {
      errorsList
        .navigationTitle("Database Errors")
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Done") {
              dismiss()
            }
          }
        }
    }
  }

  private var errorsList: some View {
    List {
      let recentErrors = monitor.recentErrors()
      if recentErrors.isEmpty {
        noErrorsView
      } else {
        ForEach(Array(recentErrors.enumerated()), id: \.offset) { index, activity in
          ErrorRowView(activity: activity, index: index)
        }
      }
    }
  }

  private var noErrorsView: some View {
    VStack(spacing: 16) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 48))
        .foregroundColor(.green)

      Text("No Errors")
        .font(.title2)
        .fontWeight(.medium)

      Text("The database is operating without any recorded errors.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding()
  }
}

private struct ErrorRowView: View {
  let activity: DatabaseActivity
  let index: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.red)

        Text("Error #\(index + 1)")
          .font(.headline)
          .foregroundColor(.red)

        Spacer()

        Text(activity.timestamp, style: .time)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if let error = activity.error {
        Text(error.localizedDescription)
          .font(.subheadline)
          .foregroundColor(.primary)
      }

      if let details = activity.details {
        VStack(alignment: .leading, spacing: 4) {
          Text("Details:")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          Text(details)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("Activity Type:")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)

        Text(activity.type.rawValue)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)
  }
}

private struct ConnectivityDebugWrapper: View {
  let datasource: (any AppDatasourceAPI)?

  var body: some View {
    if let datasource = datasource {
      DatabaseConnectivityDebugView()
        .environmentObject(datasource as! AppDatasource)
    } else {
      VStack {
        Image(systemName: "exclamationmark.triangle")
          .foregroundColor(.orange)
          .font(.largeTitle)

        Text("Database not available")
          .foregroundColor(.red)
          .font(.headline)

        Text("The database connection is not available. Please try restarting the app.")
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding()
      }
      .padding()
      .navigationTitle("Database Connectivity")
    }
  }
}

// MARK: - Preview

struct DatabaseDebugView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      DatabaseDebugView()
        .environment(\.appDatasource, AppDatasource.shared)
    }
  }
}
