//
//  DatabaseErrorView.swift
//  RecordLib
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os

/// Enhanced error view for database-related failures in views like AssetsBrowsingView
public struct DatabaseErrorView: View {
    let error: Error
    let context: String
    let onRetry: (() -> Void)?
    let onShowDashboard: (() -> Void)?
    
    @StateObject private var monitor = DatabaseMonitor.shared
    @EnvironmentObject private var datasource: AppDatasource
    
    @State private var showingDashboard = false
    @State private var isRetrying = false
    
    private let logger = Logger(subsystem: "com.record-thing", category: "database-error")
    
    public init(
        error: Error,
        context: String,
        onRetry: (() -> Void)? = nil,
        onShowDashboard: (() -> Void)? = nil
    ) {
        self.error = error
        self.context = context
        self.onRetry = onRetry
        self.onShowDashboard = onShowDashboard
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Error Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Database Error")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text(context)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Error Details Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Error Details")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.body)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    if let blackbirdError = extractBlackbirdError() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SQLite Error Code: \(blackbirdError.code)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(blackbirdError.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Database Status Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cylinder.fill")
                        .foregroundColor(monitor.currentStatus.color)
                    Text("Database Status")
                        .font(.headline)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(monitor.currentStatus.color)
                                .frame(width: 8, height: 8)
                            Text(monitor.currentStatus.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(monitor.currentStatus.color)
                        }
                    }
                    
                    HStack {
                        Text("Health:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(monitor.isHealthy ? "Healthy" : "Issues Detected")
                            .fontWeight(.medium)
                            .foregroundColor(monitor.isHealthy ? .green : .red)
                    }
                    
                    if let connectionInfo = monitor.connectionInfo {
                        HStack {
                            Text("Database:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(connectionInfo.type.displayName)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Connected:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(RelativeDateTimeFormatter().localizedString(for: connectionInfo.connectedAt, relativeTo: Date()))
                                .fontWeight(.medium)
                        }
                    }
                    
                    let stats = monitor.getStatistics()
                    HStack {
                        Text("Recent Errors:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(stats.errorCount)")
                            .fontWeight(.medium)
                            .foregroundColor(stats.errorCount > 0 ? .red : .green)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Action Buttons
            VStack(spacing: 12) {
                // Primary Actions
                HStack(spacing: 12) {
                    if let onRetry = onRetry {
                        Button(action: {
                            performRetry()
                        }) {
                            HStack {
                                if isRetrying {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Retry")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isRetrying)
                    }
                    
                    Button(action: {
                        showingDashboard = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("View Dashboard")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // Database Actions
                HStack(spacing: 12) {
                    Button(action: {
                        datasource.reloadDatabase()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Reload DB")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        datasource.resetDatabase()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                            Text("Reset DB")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Log this error view appearance
            monitor.logError(error, context: "Error view displayed: \(context)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractBlackbirdError() -> (code: Int, description: String)? {
        let errorString = error.localizedDescription
        
        // Try to extract error number from strings like "Blackbird.Database.Error error 7"
        let pattern = #"error (\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: errorString, range: NSRange(errorString.startIndex..., in: errorString)),
              let range = Range(match.range(at: 1), in: errorString),
              let code = Int(errorString[range]) else {
            return nil
        }
        
        let description = sqliteErrorDescription(for: code)
        return (code: code, description: description)
    }
    
    private func sqliteErrorDescription(for code: Int) -> String {
        switch code {
        case 1: return "SQLITE_ERROR - Generic error"
        case 2: return "SQLITE_INTERNAL - Internal logic error"
        case 3: return "SQLITE_PERM - Access permission denied"
        case 4: return "SQLITE_ABORT - Callback routine requested an abort"
        case 5: return "SQLITE_BUSY - Database file is locked"
        case 6: return "SQLITE_LOCKED - Database table is locked"
        case 7: return "SQLITE_NOMEM - Out of memory"
        case 8: return "SQLITE_READONLY - Attempt to write a readonly database"
        case 9: return "SQLITE_INTERRUPT - Operation was interrupted"
        case 10: return "SQLITE_IOERR - Disk I/O error occurred"
        case 11: return "SQLITE_CORRUPT - Database disk image is malformed"
        case 12: return "SQLITE_NOTFOUND - Unknown opcode in sqlite3_file_control()"
        case 13: return "SQLITE_FULL - Insertion failed because database is full"
        case 14: return "SQLITE_CANTOPEN - Unable to open the database file"
        case 15: return "SQLITE_PROTOCOL - Database lock protocol error"
        case 16: return "SQLITE_EMPTY - Internal use only"
        case 17: return "SQLITE_SCHEMA - Database schema changed"
        case 18: return "SQLITE_TOOBIG - String or BLOB exceeds size limit"
        case 19: return "SQLITE_CONSTRAINT - Abort due to constraint violation"
        case 20: return "SQLITE_MISMATCH - Data type mismatch"
        case 21: return "SQLITE_MISUSE - Library used incorrectly"
        case 22: return "SQLITE_NOLFS - Uses OS features not supported on host"
        case 23: return "SQLITE_AUTH - Authorization denied"
        case 24: return "SQLITE_FORMAT - Not used"
        case 25: return "SQLITE_RANGE - 2nd parameter to sqlite3_bind out of range"
        case 26: return "SQLITE_NOTADB - File opened that is not a database file"
        default: return "Unknown SQLite error code: \(code)"
        }
    }
    
    private func performRetry() {
        guard let onRetry = onRetry else { return }
        
        isRetrying = true
        
        // Add a small delay to show the loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onRetry()
            isRetrying = false
        }
    }
}
