//
//  DatabaseErrorDashboard.swift
//  RecordThing
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os

/// Comprehensive database error dashboard for debugging and monitoring
public struct DatabaseErrorDashboard: View {
  @StateObject private var monitor = DatabaseMonitor.shared
  @EnvironmentObject private var datasource: AppDatasource

  @State private var selectedTab: DashboardTab = .overview
  @State private var showingActivityDetails: DatabaseActivity?
  @State private var showingErrorDetails: DatabaseError?
  @State private var autoRefresh = true

  private let logger = Logger(subsystem: "com.record-thing", category: "database-dashboard")

  public init() {}

  public var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Status Header
        statusHeader

        // Tab Selector
        tabSelector

        // Content
        TabView(selection: $selectedTab) {
          overviewTab
            .tag(DashboardTab.overview)

          activitiesTab
            .tag(DashboardTab.activities)

          errorsTab
            .tag(DashboardTab.errors)

          diagnosticsTab
            .tag(DashboardTab.diagnostics)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
      .navigationTitle("Database Dashboard")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button(action: { monitor.checkHealth() }) {
            Image(systemName: "arrow.clockwise")
          }

          Button(action: { autoRefresh.toggle() }) {
            Image(systemName: autoRefresh ? "pause.circle" : "play.circle")
          }
        }
      }
    }
    .sheet(item: $showingActivityDetails) { activity in
      ActivityDetailView(activity: activity)
    }
    .sheet(item: $showingErrorDetails) { error in
      ErrorDetailView(error: error)
    }
    .onAppear {
      startAutoRefresh()
    }
  }

  // MARK: - Status Header

  private var statusHeader: some View {
    HStack {
      // Status Indicator
      HStack(spacing: 8) {
        Circle()
          .fill(monitor.currentStatus.color)
          .frame(width: 12, height: 12)

        Text(monitor.currentStatus.displayName)
          .font(.headline)
          .foregroundColor(monitor.currentStatus.color)
      }

      Spacer()

      // Health Indicator
      HStack(spacing: 4) {
        Image(
          systemName: monitor.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        )
        .foregroundColor(monitor.isHealthy ? .green : .red)

        Text(monitor.isHealthy ? "Healthy" : "Issues")
          .font(.subheadline)
          .foregroundColor(monitor.isHealthy ? .green : .red)
      }
    }
    .padding()
    .background(Color(.systemGray6))
  }

  // MARK: - Tab Selector

  private var tabSelector: some View {
    HStack(spacing: 0) {
      ForEach(DashboardTab.allCases, id: \.self) { tab in
        Button(action: { selectedTab = tab }) {
          VStack(spacing: 4) {
            Image(systemName: tab.icon)
              .font(.system(size: 16))

            Text(tab.title)
              .font(.caption)
          }
          .foregroundColor(selectedTab == tab ? .blue : .secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
        }
      }
    }
    .background(Color(.systemGray6))
  }

  // MARK: - Overview Tab

  private var overviewTab: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        // Connection Info
        if let connectionInfo = monitor.connectionInfo {
          connectionInfoCard(connectionInfo)
        }

        // Statistics
        statisticsCard

        // Recent Activities
        recentActivitiesCard

        // Quick Actions
        quickActionsCard
      }
      .padding()
    }
  }

  private func connectionInfoCard(_ info: DatabaseConnectionInfo) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "cylinder.fill")
          .foregroundColor(.blue)
        Text("Database Connection")
          .font(.headline)
        Spacer()
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Type:")
            .foregroundColor(.secondary)
          Spacer()
          Text(info.type.displayName)
            .fontWeight(.medium)
        }

        HStack {
          Text("Path:")
            .foregroundColor(.secondary)
          Spacer()
          Text(info.path.split(separator: "/").last.map(String.init) ?? info.path)
            .fontWeight(.medium)
            .lineLimit(1)
        }

        HStack {
          Text("Connected:")
            .foregroundColor(.secondary)
          Spacer()
          Text(
            RelativeDateTimeFormatter().localizedString(for: info.connectedAt, relativeTo: Date())
          )
          .fontWeight(.medium)
        }

        if let fileSize = info.fileSize {
          HStack {
            Text("Size:")
              .foregroundColor(.secondary)
            Spacer()
            Text(ByteCountFormatter().string(fromByteCount: fileSize))
              .fontWeight(.medium)
          }
        }
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private var statisticsCard: some View {
    let stats = monitor.getStatistics()

    return VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "chart.bar.fill")
          .foregroundColor(.green)
        Text("Statistics")
          .font(.headline)
        Spacer()
      }

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
        StatCard(title: "Activities", value: "\(stats.totalActivities)", color: .blue)
        StatCard(title: "Errors", value: "\(stats.errorCount)", color: .red)
        StatCard(title: "Connections", value: "\(stats.connectionCount)", color: .green)
        StatCard(title: "Queries", value: "\(stats.queryCount)", color: .purple)
      }

      if let uptime = stats.formattedUptime {
        HStack {
          Text("Uptime:")
            .foregroundColor(.secondary)
          Spacer()
          Text(uptime)
            .fontWeight(.medium)
        }
      }

      HStack {
        Text("Error Rate:")
          .foregroundColor(.secondary)
        Spacer()
        Text(String(format: "%.1f%%", stats.errorRate * 100))
          .fontWeight(.medium)
          .foregroundColor(stats.errorRate > 0.1 ? .red : .green)
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private var recentActivitiesCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "clock.fill")
          .foregroundColor(.orange)
        Text("Recent Activities")
          .font(.headline)
        Spacer()
        Button("View All") {
          selectedTab = .activities
        }
        .font(.caption)
      }

      ForEach(Array(monitor.activities.prefix(5))) { activity in
        ActivityRowView(activity: activity) {
          showingActivityDetails = activity
        }
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private var quickActionsCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: "wrench.and.screwdriver.fill")
          .foregroundColor(.purple)
        Text("Quick Actions")
          .font(.headline)
        Spacer()
      }

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
        ActionButton(title: "Reload DB", icon: "arrow.clockwise") {
          datasource.reloadDatabase()
        }

        ActionButton(title: "Reset DB", icon: "trash") {
          datasource.resetDatabase()
        }

        ActionButton(title: "Update DB", icon: "square.and.arrow.down") {
          Task {
            await datasource.updateDatabase()
          }
        }

        ActionButton(title: "Health Check", icon: "stethoscope") {
          monitor.checkHealth()
        }
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  // MARK: - Activities Tab

  private var activitiesTab: some View {
    List {
      ForEach(monitor.activities) { activity in
        ActivityRowView(activity: activity) {
          showingActivityDetails = activity
        }
      }
    }
    .listStyle(.plain)
  }

  // MARK: - Errors Tab

  private var errorsTab: some View {
    List {
      if let lastError = monitor.lastError {
        Section("Latest Error") {
          ErrorRowView(error: lastError) {
            showingErrorDetails = lastError
          }
        }
      }

      Section("Error History") {
        ForEach(monitor.recentErrors(), id: \.id) { activity in
          ActivityRowView(activity: activity) {
            showingActivityDetails = activity
          }
        }
      }
    }
    .listStyle(.grouped)
  }

  // MARK: - Diagnostics Tab

  private var diagnosticsTab: some View {
    List {
      Section("Database Files") {
        DatabaseFileRow(
          title: "Development DB",
          path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
        DatabaseFileRow(
          title: "Debug DB",
          path:
            "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing-debug.sqlite")
        DatabaseFileRow(
          title: "Documents DB",
          path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("record-thing.sqlite").path)
        DatabaseFileRow(
          title: "Bundle DB",
          path: Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
            ?? "Not found")
      }

      Section("System Info") {
        DiagnosticRow(title: "iOS Version", value: UIDevice.current.systemVersion)
        DiagnosticRow(
          title: "App Version",
          value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        DiagnosticRow(
          title: "Build",
          value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
        DiagnosticRow(title: "Device", value: UIDevice.current.model)
      }
    }
    .listStyle(.grouped)
  }

  // MARK: - Helper Methods

  private func startAutoRefresh() {
    guard autoRefresh else { return }

    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
      if !autoRefresh {
        timer.invalidate()
        return
      }
      // Trigger UI refresh by accessing published properties
      _ = monitor.activities.count
    }
  }
}

// MARK: - Supporting Views and Types

enum DashboardTab: CaseIterable {
  case overview, activities, errors, diagnostics

  var title: String {
    switch self {
    case .overview: return "Overview"
    case .activities: return "Activities"
    case .errors: return "Errors"
    case .diagnostics: return "Diagnostics"
    }
  }

  var icon: String {
    switch self {
    case .overview: return "house.fill"
    case .activities: return "list.bullet"
    case .errors: return "exclamationmark.triangle.fill"
    case .diagnostics: return "stethoscope"
    }
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(color)

      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .background(Color(.systemBackground))
    .cornerRadius(8)
  }
}

struct ActionButton: View {
  let title: String
  let icon: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.title2)

        Text(title)
          .font(.caption)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(Color(.systemBackground))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}

struct ActivityRowView: View {
  let activity: DatabaseActivity
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        Image(systemName: activity.statusIcon)
          .foregroundColor(activity.statusColor)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 2) {
          Text(activity.type.rawValue)
            .font(.subheadline)
            .fontWeight(.medium)

          if let details = activity.details {
            Text(details)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(1)
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
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
  }
}

struct ErrorRowView: View {
  let error: DatabaseError
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)

          Text("Database Error")
            .font(.headline)
            .foregroundColor(.red)

          Spacer()

          if let code = error.blackbirdErrorCode {
            Text("Error \(code)")
              .font(.caption)
              .padding(.horizontal, 8)
              .padding(.vertical, 2)
              .background(Color.red.opacity(0.1))
              .cornerRadius(4)
          }
        }

        Text(error.error.localizedDescription)
          .font(.subheadline)
          .foregroundColor(.primary)

        if let sqliteDescription = error.sqliteErrorDescription {
          Text(sqliteDescription)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        if let context = error.context {
          Text("Context: \(context)")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        HStack {
          Text(
            DateFormatter.localizedString(
              from: error.timestamp, dateStyle: .none, timeStyle: .medium)
          )
          .font(.caption)
          .foregroundColor(.secondary)

          Spacer()
        }
      }
      .padding()
      .background(Color.red.opacity(0.05))
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}

struct DatabaseFileRow: View {
  let title: String
  let path: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.subheadline)
        .fontWeight(.medium)

      Text(path)
        .font(.caption)
        .foregroundColor(.secondary)

      HStack {
        if FileManager.default.fileExists(atPath: path) {
          Label("Exists", systemImage: "checkmark.circle.fill")
            .font(.caption)
            .foregroundColor(.green)

          if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
            let size = attributes[.size] as? Int64
          {
            Text("• \(ByteCountFormatter().string(fromByteCount: size))")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        } else {
          Label("Not Found", systemImage: "xmark.circle.fill")
            .font(.caption)
            .foregroundColor(.red)
        }

        Spacer()
      }
    }
  }
}

struct DiagnosticRow: View {
  let title: String
  let value: String

  var body: some View {
    HStack {
      Text(title)
        .foregroundColor(.secondary)

      Spacer()

      Text(value)
        .fontWeight(.medium)
    }
  }
}
