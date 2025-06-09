//
//  ShareExtensionDebugView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os

// @DEVELOPMENT_ONLY
// This view is used only during development and doesn't need translation
struct ShareExtensionDebugView: View {
    @State private var debugInfo: [String] = []
    @State private var isLoading = false
    
    private let logger = Logger(subsystem: "com.thepia.recordthing", category: "ShareExtensionDebug")
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("ShareExtension Debug")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Check if the ShareExtension is properly installed and configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Refresh button
                Button(action: refreshDebugInfo) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh Debug Info")
                    }
                }
                .disabled(isLoading)
                
                Divider()
                
                // Debug info list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(debugInfo.enumerated()), id: \.offset) { index, info in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(info)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Test:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Open Safari or YouTube app")
                        Text("2. Navigate to any video or webpage")
                        Text("3. Tap the Share button")
                        Text("4. Look for 'RecordThing' in the share sheet")
                        Text("5. If not visible, scroll horizontally in the share sheet")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBlue).opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Debug")
            .onAppear {
                refreshDebugInfo()
            }
        }
    }
    
    private func refreshDebugInfo() {
        isLoading = true
        debugInfo.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async {
            var info: [String] = []
            
            // Basic app info
            let mainBundle = Bundle.main
            info.append("📱 Main App Bundle ID: \(mainBundle.bundleIdentifier ?? "unknown")")
            info.append("📱 Main App Version: \(mainBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown")")
            info.append("📱 Main App Build: \(mainBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown")")
            info.append("")
            
            // Check bundle structure
            let bundlePath = mainBundle.bundlePath
            info.append("📂 App Bundle Path: \(bundlePath)")
            
            let plugInsPath = bundlePath + "/PlugIns"
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: plugInsPath) {
                info.append("✅ PlugIns directory exists")
                
                do {
                    let pluginContents = try fileManager.contentsOfDirectory(atPath: plugInsPath)
                    info.append("📂 PlugIns contents: \(pluginContents.joined(separator: ", "))")
                    
                    // Check for ShareExtension.appex
                    let shareExtensionPath = plugInsPath + "/ShareExtension.appex"
                    if fileManager.fileExists(atPath: shareExtensionPath) {
                        info.append("✅ ShareExtension.appex found")
                        
                        // Get file size
                        if let attributes = try? fileManager.attributesOfItem(atPath: shareExtensionPath),
                           let fileSize = attributes[.size] as? Int64 {
                            let formatter = ByteCountFormatter()
                            formatter.allowedUnits = [.useKB, .useMB]
                            formatter.countStyle = .file
                            info.append("📊 Extension size: \(formatter.string(fromByteCount: fileSize))")
                        }
                        
                        // Try to load the extension bundle
                        if let extensionBundle = Bundle(path: shareExtensionPath) {
                            info.append("✅ Extension bundle loaded successfully")
                            info.append("🆔 Extension Bundle ID: \(extensionBundle.bundleIdentifier ?? "unknown")")
                            
                            if let displayName = extensionBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                                info.append("📋 Extension Display Name: \(displayName)")
                            }
                            
                            // Check Info.plist configuration
                            if let extensionInfo = extensionBundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any] {
                                info.append("✅ NSExtension configuration found")
                                
                                if let pointIdentifier = extensionInfo["NSExtensionPointIdentifier"] as? String {
                                    info.append("🔗 Extension Point: \(pointIdentifier)")
                                }
                                
                                if let attributes = extensionInfo["NSExtensionAttributes"] as? [String: Any],
                                   let activationRule = attributes["NSExtensionActivationRule"] as? [String: Any] {
                                    info.append("⚙️ Activation Rules:")
                                    for (key, value) in activationRule {
                                        info.append("   • \(key): \(value)")
                                    }
                                }
                            } else {
                                info.append("❌ NSExtension configuration missing")
                            }
                        } else {
                            info.append("❌ Failed to load extension bundle")
                        }
                    } else {
                        info.append("❌ ShareExtension.appex NOT found")
                    }
                } catch {
                    info.append("❌ Error reading PlugIns: \(error.localizedDescription)")
                }
            } else {
                info.append("❌ PlugIns directory does NOT exist")
            }
            
            info.append("")
            info.append("🔍 Troubleshooting Tips:")
            info.append("• Make sure you built and installed from Xcode")
            info.append("• Try restarting the app completely")
            info.append("• Check if iOS version is compatible (18.5+)")
            info.append("• Extensions may take time to register with system")
            info.append("• Try sharing from Safari first (most reliable)")
            
            DispatchQueue.main.async {
                self.debugInfo = info
                self.isLoading = false
                self.logger.info("Debug info refreshed with \(info.count) items")
            }
        }
    }
}

#Preview {
    ShareExtensionDebugView()
}
