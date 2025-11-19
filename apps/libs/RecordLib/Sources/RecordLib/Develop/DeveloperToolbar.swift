import Blackbird
import SwiftUI
import os

#if os(macOS)
  import AppKit
#endif

#if os(iOS)
  import UIKit
#endif

private let logger = Logger(subsystem: "com.recordthing.developer", category: "DeveloperSidebar")

// MARK: - DeveloperSidebar
public struct DeveloperToolbar: View {
  @Environment(\.appDatasource) private var datasource
  @ObservedObject private var captureService: CaptureService
  @ObservedObject private var cameraViewModel: CameraViewModel

  private let isCompact: Bool

  public init(
    captureService: CaptureService,
    cameraViewModel: CameraViewModel,
    isCompact: Bool = false
  ) {
    self.captureService = captureService
    self.cameraViewModel = cameraViewModel
    self.isCompact = isCompact
  }

  public var body: some View {
    if isCompact {
      compactView
    } else {
      fullView
    }
  }

  // MARK: - Compact View (for toolbar)
  private var compactView: some View {
    Menu {
      databaseSection
      stateSection
    } label: {
      #if os(macOS)
        Image(systemName: "ladybug")
          .foregroundColor(.accentColor)
          .help("Developer Tools")
      #else
        Image(systemName: "ladybug")
          .foregroundColor(.accentColor)
      #endif
    }
    #if os(macOS)
      .menuStyle(.borderlessButton)
    #endif
  }

  // MARK: - Full View (for sidebar)
  private var fullView: some View {
    List {
      databaseSection
      stateSection
    }
    .navigationTitle("Developer")
    #if os(macOS)
      .listStyle(.sidebar)
    #endif
  }

  // MARK: - Sections
  private var databaseSection: some View {
    Section("Database") {
      Button("Reload Database") {
        logger.debug("Reloading database")
        datasource?.reloadDatabase()
      }
      #if os(macOS)
        .buttonStyle(.plain)
      #endif

      Button("Reset Database") {
        if let datasource = datasource {
          datasource.resetDatabase()
        } else {
          logger.error("Datasource missing, cannot reset.")
        }
      }
      #if os(macOS)
        .buttonStyle(.plain)
      #endif

      Button("Update Database") {
        logger.debug("Updating database")
        Task {
          await datasource?.updateDatabase()
        }
      }
      #if os(macOS)
        .buttonStyle(.plain)
      #endif
    }
  }

  private var stateSection: some View {
    Section("State") {
      Group {
        Text("TODO")
        //                Text("Capture Service: \($captureService.isRunning ? "Running" : "Stopped")")
        //                Text("Camera: \(cameraViewModel.isActive ? "Active" : "Inactive")")
        //                Text("Model: \(model.loadedLang ?? "Not Loaded")")
      }
      .font(.caption)
      .foregroundColor(.secondary)
    }
  }
}

// MARK: - MockAppDatasource for Previews
public class MockAppDatasource: AppDatasourceAPI {
  public var db: Blackbird.Database?
  @Published public var translations: [String: String] = [:]
  public var loadedLang: String?

  public init() {
    // Initialize with some mock data
    translations = [
      "welcome": "Welcome",
      "record": "Record",
      "browse": "Browse",
    ]
    loadedLang = "en"
  }

  public func reloadDatabase() {
    // Mock implementation
  }

  public func resetDatabase() {
    // Mock implementation
  }

  public func updateDatabase() async {
    // Mock implementation
    try? await Task.sleep(nanoseconds: 1_000_000_000)  // Simulate 1 second delay
  }

  public func forceLocalizeReload() {
    // Mock implementation
    loadedLang = nil
  }
}

// MARK: - Preview
struct DeveloperSidebar_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      DeveloperToolbar(
        captureService: CaptureService(),
        cameraViewModel: CameraViewModel(),
        isCompact: false
      )
      .environment(\.appDatasource, MockAppDatasource())
    }

    DeveloperToolbar(
      captureService: CaptureService(),
      cameraViewModel: CameraViewModel(),
      isCompact: true
    )
    .environment(\.appDatasource, MockAppDatasource())
  }
}
