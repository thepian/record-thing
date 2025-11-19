//
//  DatabaseDetailViews.swift
//  RecordThing
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let activity: DatabaseActivity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: activity.statusIcon)
                                .foregroundColor(activity.statusColor)
                                .font(.title)
                            
                            Text(activity.type.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        
                        Text(DateFormatter.localizedString(from: activity.timestamp, dateStyle: .medium, timeStyle: .medium))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Details Section
                    if let details = activity.details {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.headline)
                            
                            Text(details)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Error Section
                    if let error = activity.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error Information")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                // Error Description
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(error.localizedDescription)
                                        .font(.body)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                // Error Type
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Type")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(String(describing: type(of: error)))
                                        .font(.body)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                // Debug Description
                                if let debugDescription = (error as? CustomDebugStringConvertible)?.debugDescription {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Debug Information")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(debugDescription)
                                            .font(.caption)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Metadata Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadata")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            MetadataRow(title: "Activity ID", value: activity.id.uuidString)
                            MetadataRow(title: "Timestamp", value: ISO8601DateFormatter().string(from: activity.timestamp))
                            MetadataRow(title: "Type", value: activity.type.rawValue)
                            MetadataRow(title: "Has Error", value: activity.error != nil ? "Yes" : "No")
                            MetadataRow(title: "Has Details", value: activity.details != nil ? "Yes" : "No")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Activity Details")
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

// MARK: - Error Detail View

struct ErrorDetailView: View {
    let error: DatabaseError
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            
                            Text("Database Error")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            if let code = error.blackbirdErrorCode {
                                Text("Error \(code)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text(DateFormatter.localizedString(from: error.timestamp, dateStyle: .medium, timeStyle: .medium))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Error Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error Description")
                            .font(.headline)
                        
                        Text(error.error.localizedDescription)
                            .font(.body)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // SQLite Error Details
                    if let sqliteDescription = error.sqliteErrorDescription {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SQLite Error Details")
                                .font(.headline)
                            
                            Text(sqliteDescription)
                                .font(.body)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Context
                    if let context = error.context {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Context")
                                .font(.headline)
                            
                            Text(context)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Query
                    if let query = error.query {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SQL Query")
                                .font(.headline)
                            
                            Text(query)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Connection Info
                    if let connectionInfo = error.connectionInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connection Information")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                MetadataRow(title: "Database Type", value: connectionInfo.type.displayName)
                                MetadataRow(title: "Path", value: connectionInfo.path)
                                MetadataRow(title: "Connected At", value: DateFormatter.localizedString(from: connectionInfo.connectedAt, dateStyle: .short, timeStyle: .medium))
                                MetadataRow(title: "Read Only", value: connectionInfo.isReadOnly ? "Yes" : "No")
                                
                                if let fileSize = connectionInfo.fileSize {
                                    MetadataRow(title: "File Size", value: ByteCountFormatter().string(fromByteCount: fileSize))
                                }
                            }
                        }
                    }
                    
                    // Troubleshooting
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Troubleshooting")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if let code = error.blackbirdErrorCode {
                                switch code {
                                case 5: // SQLITE_BUSY
                                    TroubleshootingTip(
                                        icon: "clock.fill",
                                        title: "Database Busy",
                                        description: "The database is locked by another process. Try again in a moment.",
                                        actions: ["Wait and retry", "Check for other app instances", "Restart the app"]
                                    )
                                case 7: // SQLITE_NOMEM
                                    TroubleshootingTip(
                                        icon: "memorychip.fill",
                                        title: "Out of Memory",
                                        description: "The system is running low on memory.",
                                        actions: ["Close other apps", "Restart the device", "Check available storage"]
                                    )
                                case 8: // SQLITE_READONLY
                                    TroubleshootingTip(
                                        icon: "lock.fill",
                                        title: "Read-Only Database",
                                        description: "Attempting to write to a read-only database.",
                                        actions: ["Check file permissions", "Verify database location", "Reset database"]
                                    )
                                case 11: // SQLITE_CORRUPT
                                    TroubleshootingTip(
                                        icon: "exclamationmark.triangle.fill",
                                        title: "Database Corruption",
                                        description: "The database file appears to be corrupted.",
                                        actions: ["Reset database", "Restore from backup", "Contact support"]
                                    )
                                case 14: // SQLITE_CANTOPEN
                                    TroubleshootingTip(
                                        icon: "folder.fill.badge.questionmark",
                                        title: "Cannot Open Database",
                                        description: "Unable to open the database file.",
                                        actions: ["Check file exists", "Verify permissions", "Check disk space"]
                                    )
                                default:
                                    TroubleshootingTip(
                                        icon: "questionmark.circle.fill",
                                        title: "General Database Error",
                                        description: "An unexpected database error occurred.",
                                        actions: ["Try reloading the database", "Restart the app", "Check system logs"]
                                    )
                                }
                            } else {
                                TroubleshootingTip(
                                    icon: "questionmark.circle.fill",
                                    title: "Unknown Error",
                                    description: "An unknown error occurred.",
                                    actions: ["Check system logs", "Restart the app", "Contact support"]
                                )
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Error Details")
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

// MARK: - Supporting Views

struct MetadataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct TroubleshootingTip: View {
    let icon: String
    let title: String
    let description: String
    let actions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Actions:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(actions, id: \.self) { action in
                    HStack {
                        Text("•")
                            .foregroundColor(.blue)
                        Text(action)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Extensions for Identifiable

extension DatabaseActivity: Identifiable {}
extension DatabaseError: Identifiable {
    public var id: String {
        return "\(timestamp.timeIntervalSince1970)-\(error.localizedDescription.hashValue)"
    }
}
