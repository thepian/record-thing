//
//  DatabaseDebugMenu.swift
//  RecordThing
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os

/// Debug menu for database operations and monitoring
public struct DatabaseDebugMenu: View {
    @EnvironmentObject private var datasource: AppDatasource
    @StateObject private var monitor = DatabaseMonitor.shared
    
    @State private var showingDashboard = false
    @State private var showingActivityLog = false
    @State private var isPerformingAction = false
    @State private var lastActionResult: String?
    
    private let logger = Logger(subsystem: "com.record-thing", category: "debug-menu")
    
    public init() {}
    
    public var body: some View {
        NavigationView {
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
                        Image(systemName: monitor.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
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
                    
                    StatisticRow(title: "Total Activities", value: "\(stats.totalActivities)", icon: "list.bullet")
                    StatisticRow(title: "Errors", value: "\(stats.errorCount)", icon: "exclamationmark.triangle", color: stats.errorCount > 0 ? .red : .green)
                    StatisticRow(title: "Connections", value: "\(stats.connectionCount)", icon: "link", color: .blue)
                    StatisticRow(title: "Queries", value: "\(stats.queryCount)", icon: "magnifyingglass", color: .purple)
                    
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
                            datasource.reloadDatabase()
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
                            datasource.resetDatabase()
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
                                await datasource.updateDatabase()
                            }
                        }
                    }
                    
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
                }
                
                // Monitoring Section
                Section("Monitoring") {
                    Button(action: {
                        showingDashboard = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Error Dashboard")
                                    .fontWeight(.medium)
                                
                                Text("Detailed error analysis and diagnostics")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        showingActivityLog = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Activity Log")
                                    .fontWeight(.medium)
                                
                                Text("\(monitor.activities.count) recent activities")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        monitor.clearActivities()
                        lastActionResult = "Activities cleared"
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clear Activity Log")
                                    .fontWeight(.medium)
                                
                                Text("Remove all logged activities")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
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
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                monitor.checkHealth()
            }
        }
        .sheet(isPresented: $showingDashboard) {
            DatabaseErrorDashboard()
        }
        .sheet(isPresented: $showingActivityLog) {
            DatabaseActivityLogView()
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

struct DatabaseActivityLogView: View {
    @StateObject private var monitor = DatabaseMonitor.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(monitor.activities) { activity in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: activity.statusIcon)
                                .foregroundColor(activity.statusColor)
                            
                            Text(activity.type.rawValue)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(activity.formattedTimestamp)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let details = activity.details {
                            Text(details)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let error = activity.error {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Activity Log")
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

// MARK: - Preview

struct DatabaseDebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DatabaseDebugMenu()
            .environmentObject(AppDatasource.shared)
    }
}
