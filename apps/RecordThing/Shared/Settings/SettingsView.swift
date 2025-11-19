//
//  SettingsView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 08.06.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import AVFoundation
import Blackbird
import RecordLib
import SwiftUI

// MARK: - Improved Settings View

struct ImprovedSettingsView: View {
  let captureService: CaptureService?
  let designSystem: DesignSystemSetup?

  // @StateObject private var settingsManager = SettingsManager()
  @State private var settingsManager = MockSettingsManager()
  @State private var showingUpgradeSheet = false
  @State private var showingDatabaseResetAlert = false
  @State private var showingTranslationSourceInfo = false
  @State private var translationStats = TranslationStats()

  init(captureService: CaptureService? = nil, designSystem: DesignSystemSetup? = nil) {
    self.captureService = captureService
    self.designSystem = designSystem
  }

  var body: some View {
    List {
      Section {
        HStack {
          Image(systemName: "person.circle.fill")
            .font(.title2)
            .foregroundColor(.accentColor)

          VStack(alignment: .leading) {
            Text(settingsManager.accountName)
              .font(.headline)
            Text(settingsManager.accountEmail)
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          Button("Edit") {
            // Edit account
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
      } header: {
        Text("Account")
      }

      Section {
        HStack {
          VStack(alignment: .leading) {
            HStack {
              Text(settingsManager.currentPlan.displayName)
                .font(.headline)

              if settingsManager.currentPlan == .premium {
                Image(systemName: "crown.fill")
                  .foregroundColor(.yellow)
                  .font(.caption)
              }

              Spacer()
            }
            Text(settingsManager.currentPlan.description)
              .font(.caption)
              .foregroundColor(.secondary)
          }

          if settingsManager.currentPlan == .free {
            Button("Upgrade") {
              showingUpgradeSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
          } else {
            Text("Active")
              .font(.caption)
              .foregroundColor(.green)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.green.opacity(0.1))
              .clipShape(Capsule())
          }
        }
      } header: {
        Text("Plan & Billing")
      }

      Section {
        // Auto Sync Toggle
        HStack {
          Label("Auto Sync", systemImage: "arrow.triangle.2.circlepath")
          Spacer()
          Toggle("", isOn: $settingsManager.autoSyncEnabled)
            .disabled(settingsManager.currentPlan == .free)
        }

        if settingsManager.currentPlan == .premium {
          // Selective Sync Toggle
          HStack {
            Label("Selective Sync", systemImage: "checkmark.circle")
            Spacer()
            Toggle("", isOn: $settingsManager.selectiveSyncEnabled)
          }

          // iCloud Backup Toggle
          HStack {
            Label("iCloud Backup", systemImage: "icloud")
            Spacer()
            Toggle("", isOn: $settingsManager.iCloudBackupEnabled)
          }
        }

        // iCloud Documents Sync (available for all users)
        Button(action: {
          Task {
            await settingsManager.triggeriCloudDocumentsSync()
          }
        }) {
          HStack {
            Label("Sync iCloud Documents", systemImage: "icloud.and.arrow.up")
            Spacer()
            if settingsManager.isSyncing {
              ProgressView()
                .controlSize(.small)
            }
          }
        }
        .disabled(settingsManager.isSyncing || !SimpleiCloudManager.shared.isAvailable)

        // Manual Sync Button (Premium only)
        Button(action: {
          Task {
            await settingsManager.triggerManualSync()
          }
        }) {
          HStack {
            Label("Sync Now", systemImage: "arrow.clockwise")
            Spacer()
            if settingsManager.isSyncing {
              ProgressView()
                .controlSize(.small)
            }
          }
        }
        .disabled(settingsManager.isSyncing || settingsManager.currentPlan == .free)

        // Last Sync Status
        HStack {
          Label("Last Sync", systemImage: "clock")
          Spacer()
          Text(settingsManager.lastSyncStatus)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        NavigationLink("iCloud Debug") {
          SimpleiCloudDebugView()
        }

      } header: {
        Text("Sync & Backup")
      } footer: {
        if settingsManager.currentPlan == .free {
          Text(
            "iCloud Documents sync is available for all users. Advanced sync features require Premium plan."
          )
        } else {
          Text(
            "Your data is automatically synced across all your devices with full Premium features.")
        }
      }

      Section {
        HStack {
          Label("Contribute to AI Training", systemImage: "brain")
          Spacer()
          Toggle("", isOn: $settingsManager.contributeToAI)
            .disabled(settingsManager.currentPlan == .free)  // Free tier always contributes
        }

        // Private Recordings (Premium only)
        if settingsManager.currentPlan == .premium {
          HStack {
            Label("Mark New Recordings Private", systemImage: "lock")
            Spacer()
            Toggle("", isOn: $settingsManager.defaultPrivateRecordings)
          }
        }

        Button("Privacy Policy") {
          // Show privacy policy
        }

      } header: {
        Text("Privacy & Data")
      } footer: {
        if settingsManager.currentPlan == .free {
          Text("Free tier recordings help improve our AI. Upgrade to Premium for privacy controls.")
        } else {
          Text("You have full control over your data privacy and AI training contributions.")
        }
      }

      Section {
        HStack {
          Label("Demo Mode", systemImage: "play.circle")
          Spacer()
          Toggle("", isOn: $settingsManager.demoModeEnabled)
        }

        if settingsManager.demoModeEnabled {
          Button(action: {
            Task {
              await settingsManager.resetDemoData()
            }
          }) {
            HStack {
              Label("Reset Demo Data", systemImage: "arrow.clockwise")
              Spacer()
              if settingsManager.isResettingDemo {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isResettingDemo)

          Button(action: {
            Task {
              await settingsManager.updateDemoData()
            }
          }) {
            HStack {
              Label("Update Demo Data", systemImage: "arrow.down.circle")
              Spacer()
              if settingsManager.isUpdatingDemo {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isUpdatingDemo)
        }

      } header: {
        Text("Demo Mode")
      } footer: {
        if settingsManager.demoModeEnabled {
          Text(
            "Demo mode limits database modifications and disables cloud sync to protect demo data.")
        } else {
          Text("Enable demo mode to explore the app with sample data.")
        }
      }

      #if DEBUG
        Section {
          // Database Controls
          NavigationLink("Database Debug") {
            DatabaseDebugView()
          }

          Button(action: {
            Task {
              await settingsManager.triggerDatabaseBackup()
            }
          }) {
            HStack {
              Label("Backup Database", systemImage: "externaldrive")
              Spacer()
              if settingsManager.isBackingUp {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isBackingUp)

          Button(action: {
            Task {
              await settingsManager.reloadDatabase()
            }
          }) {
            HStack {
              Label("Reload Database", systemImage: "arrow.clockwise")
              Spacer()
              if settingsManager.isReloading {
                ProgressView()
                  .controlSize(.small)
              }
            }
          }
          .disabled(settingsManager.isReloading)

          Button("Reset Database") {
            showingDatabaseResetAlert = true
          }
          .foregroundColor(.red)

          // Translation Source Toggle
          HStack {
            Label("Use Source Translations", systemImage: "doc.text")

            Button(action: {
              showingTranslationSourceInfo = true
            }) {
              Image(systemName: "info.circle")
                .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Spacer()
            Toggle("", isOn: $settingsManager.useSourceTranslations)
          }

          // Translations Management
          NavigationLink(destination: TranslationsManagementView()) {
            HStack {
              Label("Translations", systemImage: "globe")
              Spacer()
              VStack(alignment: .trailing, spacing: 2) {
                Text("\(translationStats.dbCount) in DB")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text("\(translationStats.hardcodedCount) hardcoded")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          NavigationLink("Memory Monitor") {
            MemoryMonitorView()
          }

          // Camera Controls
          if let captureService = captureService, let designSystem = designSystem {
            Group {
              HStack {
                Text("Camera Stream")
                Spacer()
                CameraSwitcher(captureService: captureService, designSystem: designSystem)
              }

              HStack {
                Text("Power Mode")
                Spacer()
                CameraSubduedSwitcher(captureService: captureService, designSystem: designSystem)
              }

              VStack(alignment: .leading, spacing: 4) {
                Text("Capture Service Info")
                  .font(.headline)
                CaptureServiceInfo(captureService: captureService)
              }
            }
          }

        } header: {
          Text("Development")
        } footer: {
          Text("Development tools for debugging and testing. Camera controls moved from sidebar.")
        }
      #endif

      Section {
        HStack {
          Text("Version")
          Spacer()
          Text(settingsManager.appVersion)
            .foregroundColor(.secondary)
        }

        HStack {
          Text("Build")
          Spacer()
          Text(settingsManager.buildNumber)
            .foregroundColor(.secondary)
        }

        Button("Help & Support") {
          // Show help
        }
      } header: {
        Text("About")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle("Settings")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    .sheet(isPresented: $showingUpgradeSheet) {
      SimpleUpgradeView()
    }
    .alert("Reset Database", isPresented: $showingDatabaseResetAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        Task {
          await settingsManager.resetDatabase()
        }
      }
    } message: {
      Text(
        "This will permanently delete all your data and reset the app to its initial state. This action cannot be undone."
      )
    }
    .alert("Use Source Translations", isPresented: $showingTranslationSourceInfo) {
      Button("OK") {}
    } message: {
      Text(
        "When enabled, translations are loaded from the source repository SQLite file instead of the bundled database. This is useful for development and testing new translations before they are included in the app bundle."
      )
    }
    .onAppear {
      settingsManager.loadSettings()
      loadTranslationStats()
    }
  }

  private func loadTranslationStats() {
    Task {
      let stats = await TranslationStatsLoader.loadStats()
      await MainActor.run {
        self.translationStats = stats
      }
    }
  }
}

struct SimpleUpgradeView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
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

        Spacer()

        Button("Start Free Trial") {
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Text("$4.99/month after 7-day free trial")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Translations Management View

struct TranslationsManagementView: View {
  @State private var translations: [TranslationItem] = []
  @State private var isLoading = false
  @State private var searchText = ""
  @State private var selectedContext = "All"
  @State private var stats = TranslationStats()

  private let contexts = [
    "All", "ui", "database", "settings", "error", "navigation", "premium", "demo",
  ]

  var filteredTranslations: [TranslationItem] {
    var filtered = translations

    // Filter by context
    if selectedContext != "All" {
      filtered = filtered.filter { $0.context == selectedContext }
    }

    // Filter by search text
    if !searchText.isEmpty {
      filtered = filtered.filter { translation in
        translation.key.localizedCaseInsensitiveContains(searchText)
          || translation.value.localizedCaseInsensitiveContains(searchText)
      }
    }

    return filtered.sorted { $0.key < $1.key }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Stats Header
      statsHeader

      // Filters
      filtersSection

      // Translations List
      translationsListView
    }
    .navigationTitle("Translations")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Refresh") {
          loadTranslations()
        }
        .disabled(isLoading)
      }
    }
    .onAppear {
      loadTranslations()
    }
  }

  private var translationsListView: some View {
    Group {
      if isLoading {
        Spacer()
        ProgressView("Loading translations...")
        Spacer()
      } else if filteredTranslations.isEmpty {
        emptyStateView
      } else {
        translationsList
      }
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Spacer()

      Image(systemName: "globe.badge.chevron.backward")
        .font(.system(size: 48))
        .foregroundColor(.secondary)

      Text("No translations found")
        .font(.title2)
        .fontWeight(.medium)

      if !searchText.isEmpty {
        Text("Try adjusting your search or filter")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }

  private var translationsList: some View {
    List {
      ForEach(0..<filteredTranslations.count, id: \.self) { index in
        let translation = filteredTranslations[index]
        HStack {
          Text("#\(index + 1)")
            .font(.caption2)
            .foregroundColor(.secondary)
            .frame(width: 30, alignment: .leading)

          TranslationRowView(translation: translation)
        }
      }
    }
  }

  private var statsHeader: some View {
    VStack(spacing: 12) {
      HStack(spacing: 20) {
        StatCard(title: "Current DB", value: "\(stats.dbCount)", color: .blue)
        StatCard(title: "Default DB", value: "\(stats.defaultDbCount)", color: .green)
        StatCard(title: "Hardcoded", value: "\(stats.hardcodedCount)", color: .orange)
      }

      HStack {
        Text("Total: \(translations.count) translations")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()

        if !searchText.isEmpty || selectedContext != "All" {
          Text("Filtered: \(filteredTranslations.count)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
  }

  private var filtersSection: some View {
    VStack(spacing: 8) {
      // Search
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)

        TextField("Search translations...", text: $searchText)
          .textFieldStyle(.plain)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.gray.opacity(0.05))
      .cornerRadius(8)

      // Context Filter
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(contexts, id: \.self) { context in
            Button(context) {
              selectedContext = context
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(selectedContext == context ? .white : .primary)
            .background(selectedContext == context ? Color.accentColor : Color.clear)
            .cornerRadius(6)
          }
        }
        .padding(.horizontal)
      }
    }
    .padding()
  }

  private func loadTranslations() {
    isLoading = true

    Task {
      let loadedTranslations = await TranslationLoader.loadAllTranslations()
      let loadedStats = await TranslationStatsLoader.loadStats()

      await MainActor.run {
        self.translations = loadedTranslations
        self.stats = loadedStats
        self.isLoading = false

        // Debug logging
        print("🔍 UI: Loaded \(loadedTranslations.count) translations")
        if loadedTranslations.count > 0 {
          print(
            "🔍 UI: First translation: \(loadedTranslations[0].key) = \(loadedTranslations[0].value)"
          )
          if loadedTranslations.count > 1 {
            print(
              "🔍 UI: Second translation: \(loadedTranslations[1].key) = \(loadedTranslations[1].value)"
            )
          }
        }
        print("🔍 UI: Filtered count: \(self.filteredTranslations.count)")
      }
    }
  }
}

// MARK: - Translation Stats

struct TranslationStats {
  var dbCount: Int = 0
  var defaultDbCount: Int = 0
  var hardcodedCount: Int = 0
}

class TranslationStatsLoader {
  static func loadStats() async -> TranslationStats {
    var stats = TranslationStats()

    print("🔍 Loading translation statistics...")

    // Count translations in current database
    if let datasource = AppDatasource.shared.db {
      do {
        let dbRows: [Dictionary] = try await datasource.query(
          "SELECT COUNT(*) as count FROM translations WHERE lang = 'en'")
        if let count = dbRows.first?["count"]?.intValue {
          stats.dbCount = count
          print("📊 Current DB: \(count) translations")
        }
      } catch {
        print("❌ Error counting database translations: \(error)")
      }
    } else {
      print("⚠️ No current database connection for stats")
    }

    // Count translations in default database
    if let bundleDbPath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite") {
      do {
        let defaultDb = try Blackbird.Database(path: bundleDbPath)
        let defaultRows: [Dictionary] = try await defaultDb.query(
          "SELECT COUNT(*) as count FROM translations WHERE lang = 'en'")
        if let count = defaultRows.first?["count"]?.intValue {
          stats.defaultDbCount = count
          print("📊 Default DB: \(count) translations")
        }
      } catch {
        print("❌ Error counting default database translations: \(error)")
      }
    } else {
      print("❌ Could not find bundled database for stats")
    }

    // TODO: Scan Swift files for hardcoded strings
    // For now, use a placeholder count
    stats.hardcodedCount = 42

    print(
      "✅ Translation stats loaded: DB=\(stats.dbCount), Default=\(stats.defaultDbCount), Hardcoded=\(stats.hardcodedCount)"
    )
    return stats
  }
}

struct TranslationItem: Identifiable {
  let id = UUID()
  let key: String
  let value: String
  let context: String
  let language: String
}

struct TranslationRowView: View {
  let translation: TranslationItem

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(translation.key)
          .font(.headline)
          .foregroundColor(.primary)
          .lineLimit(2)

        Spacer()

        Text(translation.context)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(contextColor.opacity(0.2))
          .foregroundColor(contextColor)
          .cornerRadius(4)
      }

      Text(translation.value)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
        .lineLimit(3)
    }
    .padding(.vertical, 4)
  }

  private var contextColor: Color {
    switch translation.context {
    case "ui": return .blue
    case "database": return .purple
    case "settings": return .green
    case "error": return .red
    case "navigation": return .orange
    case "premium": return .yellow
    case "demo": return .pink
    default: return .gray
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
  }
}

class TranslationLoader {
  static func loadAllTranslations() async -> [TranslationItem] {
    var translations: [TranslationItem] = []

    // Try to load from current database first
    if let datasource = AppDatasource.shared.db {
      do {
        let rows: [Dictionary] = try await datasource.query(
          "SELECT key, value, COALESCE(context, 'unknown') as context, lang FROM translations WHERE lang = 'en' ORDER BY key"
        )

        print("📊 Loaded \(rows.count) translations from current database")

        for row in rows {
          if let key = row["key"]?.stringValue,
            let value = row["value"]?.stringValue,
            let context = row["context"]?.stringValue,
            let lang = row["lang"]?.stringValue
          {
            translations.append(
              TranslationItem(
                key: key,
                value: value,
                context: context,
                language: lang
              ))
          }
        }
      } catch {
        print("❌ Error loading translations from current database: \(error)")
      }
    } else {
      print("⚠️ No current database connection available")
    }

    // If no translations found, try loading from bundled database
    if translations.isEmpty {
      print("🔄 Attempting to load from bundled database...")
      if let bundleDbPath = Bundle.main.path(forResource: "default-record-thing", ofType: "sqlite")
      {
        do {
          let bundleDb = try Blackbird.Database(path: bundleDbPath)
          let rows: [Dictionary] = try await bundleDb.query(
            "SELECT key, value, COALESCE(context, 'unknown') as context, lang FROM translations WHERE lang = 'en' ORDER BY key"
          )

          print("📊 Loaded \(rows.count) translations from bundled database")

          for row in rows {
            if let key = row["key"]?.stringValue,
              let value = row["value"]?.stringValue,
              let context = row["context"]?.stringValue,
              let lang = row["lang"]?.stringValue
            {
              translations.append(
                TranslationItem(
                  key: key,
                  value: value,
                  context: context,
                  language: lang
                ))
            }
          }
        } catch {
          print("❌ Error loading translations from bundled database: \(error)")
        }
      } else {
        print("❌ Could not find bundled database")
      }
    }

    print("✅ Final translation count: \(translations.count)")
    return translations
  }
}

// MARK: - Mock Settings Manager (Temporary)

class MockSettingsManager: ObservableObject {
  @Published var accountName: String = "Demo User"
  @Published var accountEmail: String = "demo@thepia.com"
  @Published var currentPlan: UserPlan = .free
  @Published var autoSyncEnabled: Bool = false
  @Published var selectiveSyncEnabled: Bool = false
  @Published var iCloudBackupEnabled: Bool = false
  @Published var isSyncing: Bool = false
  @Published var lastSyncStatus: String = "Never"
  @Published var contributeToAI: Bool = true
  @Published var defaultPrivateRecordings: Bool = false
  @Published var demoModeEnabled: Bool = false
  @Published var isResettingDemo: Bool = false
  @Published var isUpdatingDemo: Bool = false
  @Published var isBackingUp: Bool = false
  @Published var isReloading: Bool = false
  @Published var appVersion: String = "1.0.0"
  @Published var buildNumber: String = "1"
  @Published var useSourceTranslations: Bool = false

  func loadSettings() {
    // Mock implementation
  }

  func triggerManualSync() async {
    isSyncing = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    isSyncing = false
    lastSyncStatus = "Just now"
  }

  func triggeriCloudDocumentsSync() async {
    isSyncing = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    isSyncing = false
  }

  func resetDemoData() async {
    isResettingDemo = true
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    isResettingDemo = false
  }

  func updateDemoData() async {
    isUpdatingDemo = true
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    isUpdatingDemo = false
  }

  func triggerDatabaseBackup() async {
    isBackingUp = true
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    isBackingUp = false
  }

  func reloadDatabase() async {
    isReloading = true
    try? await Task.sleep(nanoseconds: 1_500_000_000)
    isReloading = false
  }

  func resetDatabase() async {
    try? await Task.sleep(nanoseconds: 2_000_000_000)
  }
}

enum UserPlan: String, CaseIterable {
  case free = "free"
  case premium = "premium"

  var displayName: String {
    switch self {
    case .free: return "Free"
    case .premium: return "Premium"
    }
  }

  var description: String {
    switch self {
    case .free: return "Basic recording and local storage"
    case .premium: return "Advanced features with cloud sync"
    }
  }
}

#if DEBUG
  struct ImprovedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
      ImprovedSettingsView(
        captureService: CaptureService(),
        designSystem: .light
      )
    }
  }
#endif
