//
//  SettingsViews.swift
//  RecordThing
//
//  Created by AI Assistant on 07.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import RecordLib

// MARK: - Upgrade View

struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
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
                }
                .padding(.top, 40)
                
                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "icloud", title: "Cloud Sync", description: "Sync across all your devices")
                    FeatureRow(icon: "lock", title: "Privacy Controls", description: "Keep recordings private")
                    FeatureRow(icon: "person.2", title: "Advanced Sharing", description: "Share with other users")
                    FeatureRow(icon: "gear", title: "Custom Workflows", description: "Create your own processes")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Pricing
                VStack(spacing: 16) {
                    Button("Start Free Trial") {
                        // Handle upgrade
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Text("$4.99/month after 7-day free trial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Subscription Management View

struct SubscriptionManagementView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Premium Plan")
                            .font(.headline)
                        Text("Active since January 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("$4.99/month")
                        .font(.headline)
                }
                
                Button("Manage in App Store") {
                    // Open App Store subscription management
                }
                
                Button("Cancel Subscription") {
                    // Handle cancellation
                }
                .foregroundColor(.red)
                
            } header: {
                Text("Current Subscription")
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: January 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                    Text("We collect minimal data necessary to provide our services...")
                    
                    Text("AI Training")
                        .font(.headline)
                    Text("Free tier recordings may be used to improve our AI models...")
                    
                    Text("Data Security")
                        .font(.headline)
                    Text("Your data is encrypted and stored securely...")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @State private var isExporting = false
    
    var body: some View {
        List {
            Section {
                Button(action: {
                    exportData()
                }) {
                    HStack {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isExporting)
                
            } header: {
                Text("Export Options")
            } footer: {
                Text("Export your data in JSON format for backup or migration purposes.")
            }
        }
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            // Simulate export
            try await Task.sleep(nanoseconds: 2_000_000_000)
            isExporting = false
        }
    }
}

// MARK: - Database Debug View

struct DatabaseDebugView: View {
    @Environment(\.appDatasource) private var appDatasource
    @State private var databaseInfo: DatabaseInfo?
    
    var body: some View {
        List {
            if let info = databaseInfo {
                Section("Database Information") {
                    HStack {
                        Text("Path")
                        Spacer()
                        Text(info.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Size")
                        Spacer()
                        Text(info.size)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Tables")
                        Spacer()
                        Text("\(info.tableCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Recent Queries") {
                    ForEach(info.recentQueries, id: \.self) { query in
                        Text(query)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Database Debug")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDatabaseInfo()
        }
    }
    
    private func loadDatabaseInfo() {
        // Simulate loading database info
        databaseInfo = DatabaseInfo(
            path: "/path/to/database.sqlite",
            size: "2.4 MB",
            tableCount: 8,
            recentQueries: [
                "SELECT * FROM things LIMIT 10",
                "INSERT INTO evidence...",
                "UPDATE account SET..."
            ]
        )
    }
}

struct DatabaseInfo {
    let path: String
    let size: String
    let tableCount: Int
    let recentQueries: [String]
}

// MARK: - ShareExtension Debug View

struct ShareExtensionDebugView: View {
    var body: some View {
        List {
            Section("ShareExtension Status") {
                HStack {
                    Text("Extension Loaded")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Last Share")
                    Spacer()
                    Text("2 minutes ago")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Recent Shares") {
                Text("YouTube: Rick Roll")
                Text("Web Page: Apple.com")
                Text("Text: Meeting notes")
            }
        }
        .navigationTitle("ShareExtension Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Database Error Dashboard

struct DatabaseErrorDashboard: View {
    var body: some View {
        List {
            Section("Error Summary") {
                HStack {
                    Text("Total Errors")
                    Spacer()
                    Text("3")
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Last Error")
                    Spacer()
                    Text("5 minutes ago")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Recent Errors") {
                ErrorRow(message: "Database locked", time: "5 min ago")
                ErrorRow(message: "Sync failed", time: "1 hour ago")
                ErrorRow(message: "Query timeout", time: "2 hours ago")
            }
        }
        .navigationTitle("Error Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ErrorRow: View {
    let message: String
    let time: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text(message)
                    .font(.caption)
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Help & Support View

struct HelpSupportView: View {
    var body: some View {
        List {
            Section("Get Help") {
                Link("FAQ", destination: URL(string: "https://thepia.com/recordthing/faq")!)
                Link("Contact Support", destination: URL(string: "mailto:support@thepia.com")!)
                Link("User Guide", destination: URL(string: "https://thepia.com/recordthing/guide")!)
            }
            
            Section("Community") {
                Link("Discord", destination: URL(string: "https://discord.gg/thepia")!)
                Link("Reddit", destination: URL(string: "https://reddit.com/r/recordthing")!)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - What's New View

struct WhatsNewView: View {
    var body: some View {
        List {
            Section("Version 1.0.0") {
                Text("• ShareExtension support")
                Text("• Premium tier features")
                Text("• Cloud synchronization")
                Text("• Privacy controls")
            }
        }
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.inline)
    }
}
