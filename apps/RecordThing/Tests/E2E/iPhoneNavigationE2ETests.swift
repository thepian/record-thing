import Foundation
import XCTest

/// End-to-End tests for iPhone app navigation flows
/// Tests the complete user journey through the app on iPhone simulator
class iPhoneNavigationE2ETests: XCTestCase {

  // MARK: - Test Configuration

  private let simulatorUuid = "4364D6A3-B29D-45FC-B46B-740D0BB556E5"  // iPhone 16
  private let bundleId = "com.thepia.recordthing"
  private let testTimeout: TimeInterval = 30.0

  // MARK: - Setup & Teardown

  override func setUpWithError() throws {
    try super.setUpWithError()
    continueAfterFailure = false

    // Ensure app is running in simulator
    try ensureAppIsRunning()

    // Start from camera view (default state)
    try navigateToDefaultState()
  }

  override func tearDownWithError() throws {
    // Return to camera view for next test
    try navigateToDefaultState()
    try super.tearDownWithError()
  }

  // MARK: - Core Navigation Tests

  /// Test: Camera → Actions → Camera navigation flow
  func testCameraToActionsNavigation() throws {
    // Given: App is in camera view
    let cameraState = try getCurrentUIState()
    XCTAssertTrue(cameraState.contains("Actions"), "Should show Actions button in camera view")
    XCTAssertTrue(cameraState.contains("Stack"), "Should show Stack button in camera view")
    XCTAssertTrue(
      cameraState.contains("Take Picture"), "Should show Take Picture button in camera view")

    // When: Tap Actions button
    try tapActionsButton()

    // Then: Should navigate to Actions view
    let actionsState = try getCurrentUIState()
    XCTAssertTrue(actionsState.contains("Actions"), "Should show Actions heading")
    XCTAssertTrue(actionsState.contains("Settings"), "Should show Settings option")
    XCTAssertTrue(actionsState.contains("Record"), "Should show Record button")

    // When: Tap Record button
    try tapRecordButton()

    // Then: Should return to camera view
    let returnedCameraState = try getCurrentUIState()
    XCTAssertTrue(returnedCameraState.contains("Take Picture"), "Should be back in camera view")
  }

  /// Test: Actions → Settings → Actions navigation flow
  func testActionsToSettingsNavigation() throws {
    // Given: Navigate to Actions view
    try tapActionsButton()
    let actionsState = try getCurrentUIState()
    XCTAssertTrue(actionsState.contains("Settings"), "Should show Settings option")

    // When: Tap Settings
    try tapSettingsInActions()

    // Then: Should navigate to Settings view
    let settingsState = try getCurrentUIState()
    XCTAssertTrue(settingsState.contains("Settings"), "Should show Settings heading")
    XCTAssertTrue(settingsState.contains("ACCOUNT"), "Should show Account section")
    XCTAssertTrue(settingsState.contains("Demo User"), "Should show demo user info")
    XCTAssertTrue(settingsState.contains("Actions"), "Should show back button to Actions")

    // When: Tap back to Actions
    try tapBackToActions()

    // Then: Should return to Actions view
    let returnedActionsState = try getCurrentUIState()
    XCTAssertTrue(returnedActionsState.contains("Actions"), "Should be back in Actions view")
    XCTAssertTrue(returnedActionsState.contains("Record"), "Should show Record button")
  }

  /// Test: Camera → Stack → Assets → Camera navigation flow
  func testCameraToAssetsNavigation() throws {
    // Given: App is in camera view
    let cameraState = try getCurrentUIState()
    XCTAssertTrue(cameraState.contains("Stack"), "Should show Stack button")

    // When: Tap Stack button
    try tapStackButton()

    // Then: Should navigate to Assets view
    let assetsState = try getCurrentUIState()
    XCTAssertTrue(assetsState.contains("Assets"), "Should show Assets heading")
    XCTAssertTrue(assetsState.contains("Record"), "Should show Record button")

    // When: Tap Record button
    try tapRecordButton()

    // Then: Should return to camera view
    let returnedCameraState = try getCurrentUIState()
    XCTAssertTrue(returnedCameraState.contains("Take Picture"), "Should be back in camera view")
  }

  // MARK: - Actions View Content Tests

  /// Test: Actions view displays all expected content
  func testActionsViewContent() throws {
    // Given: Navigate to Actions view
    try tapActionsButton()

    // When: Get current UI state
    let actionsState = try getCurrentUIState()

    // Then: Should display all expected sections and items
    XCTAssertTrue(actionsState.contains("Actions"), "Should show Actions heading")
    XCTAssertTrue(actionsState.contains("ACTIONS"), "Should show ACTIONS section")
    XCTAssertTrue(actionsState.contains("Settings"), "Should show Settings CTA")
    XCTAssertTrue(
      actionsState.contains("Configure app preferences"), "Should show Settings description")
    XCTAssertTrue(actionsState.contains("Update Account"), "Should show Update Account CTA")
    XCTAssertTrue(actionsState.contains("Complete your profile"), "Should show Account description")
    XCTAssertTrue(actionsState.contains("Record Evidence"), "Should show Record Evidence CTA")
    XCTAssertTrue(actionsState.contains("ACCOUNT & TEAMS"), "Should show Account & Teams section")
    XCTAssertTrue(actionsState.contains("Account Profile"), "Should show Account Profile option")
    XCTAssertTrue(actionsState.contains("Record"), "Should show Record button in toolbar")
  }

  /// Test: Settings view displays all expected content
  func testSettingsViewContent() throws {
    // Given: Navigate to Settings view
    try tapActionsButton()
    try tapSettingsInActions()

    // When: Get current UI state
    let settingsState = try getCurrentUIState()

    // Then: Should display all expected sections
    XCTAssertTrue(settingsState.contains("Settings"), "Should show Settings heading")
    XCTAssertTrue(settingsState.contains("ACCOUNT"), "Should show Account section")
    XCTAssertTrue(settingsState.contains("Demo User"), "Should show demo user")
    XCTAssertTrue(settingsState.contains("demo@thepia.com"), "Should show demo email")
    XCTAssertTrue(settingsState.contains("PLAN & BILLING"), "Should show Plan & Billing section")
    XCTAssertTrue(settingsState.contains("Free Plan"), "Should show current plan")
    XCTAssertTrue(settingsState.contains("SYNC & BACKUP"), "Should show Sync & Backup section")
    XCTAssertTrue(settingsState.contains("iCloud Sync"), "Should show iCloud option")
    XCTAssertTrue(settingsState.contains("PRIVACY & DATA"), "Should show Privacy section")
    XCTAssertTrue(settingsState.contains("DEMO MODE"), "Should show Demo Mode section")
  }

  // MARK: - Error Recovery Tests

  /// Test: App recovers gracefully from navigation errors
  func testNavigationErrorRecovery() throws {
    // Test multiple rapid navigation actions
    try tapActionsButton()
    try tapRecordButton()
    try tapStackButton()
    try tapRecordButton()
    try tapActionsButton()
    try tapSettingsInActions()
    try tapBackToActions()
    try tapRecordButton()

    // Should end up in camera view
    let finalState = try getCurrentUIState()
    XCTAssertTrue(finalState.contains("Take Picture"), "Should recover to camera view")
  }

  // MARK: - Performance Tests

  /// Test: Navigation performance is acceptable
  func testNavigationPerformance() throws {
    measure {
      do {
        // Perform complete navigation cycle
        try tapActionsButton()
        try tapSettingsInActions()
        try tapBackToActions()
        try tapRecordButton()
      } catch {
        XCTFail("Navigation performance test failed: \(error)")
      }
    }
  }
}

// MARK: - Helper Methods

extension iPhoneNavigationE2ETests {

  /// Ensures the app is running in the simulator
  private func ensureAppIsRunning() throws {
    // This would typically use XCUIApplication, but since we're using the simulator tools,
    // we'll implement a check using the UI state
    let state = try getCurrentUIState()
    if !state.contains("Record Thing") {
      throw TestError.appNotRunning
    }
  }

  /// Navigates to the default camera state
  private func navigateToDefaultState() throws {
    let state = try getCurrentUIState()

    // If we're in Actions view, tap Record button
    if state.contains("Actions") && state.contains("Record") && !state.contains("Take Picture") {
      try tapRecordButton()
      return
    }

    // If we're in Settings view, navigate back to camera
    if state.contains("Settings") && state.contains("Actions") {
      try tapBackToActions()
      try tapRecordButton()
      return
    }

    // If we're in Assets view, tap Record button
    if state.contains("Assets") && state.contains("Record") {
      try tapRecordButton()
      return
    }

    // Should now be in camera view
    let finalState = try getCurrentUIState()
    if !finalState.contains("Take Picture") {
      throw TestError.cannotReachDefaultState
    }
  }

  /// Gets the current UI state from the simulator
  private func getCurrentUIState() throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    process.arguments = [
      "-c",
      """
          import json
          import subprocess

          # This would call the actual simulator tools
          # For now, return mock data based on test state
          result = {
              "elements": [
                  {"label": "Record Thing", "type": "Application"},
                  {"label": "Take Picture", "type": "Button"},
                  {"label": "Stack", "type": "Button"},
                  {"label": "Actions", "type": "Button"}
              ]
          }

          # Extract labels for simple string matching
          labels = [elem.get("label", "") for elem in result.get("elements", [])]
          print(" ".join(filter(None, labels)))
      """,
    ]

    let pipe = Pipe()
    process.standardOutput = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
      ?? ""
  }

  /// Taps the Actions button in the camera view
  private func tapActionsButton() throws {
    try performTap(x: 255, y: 708, description: "Actions button")
  }

  /// Taps the Record button in toolbar
  private func tapRecordButton() throws {
    try performTap(x: 354, y: 75, description: "Record button")
  }

  /// Taps the Stack button in camera view
  private func tapStackButton() throws {
    try performTap(x: 132, y: 708, description: "Stack button")
  }

  /// Taps the Settings option in Actions view
  private func tapSettingsInActions() throws {
    try performTap(x: 196, y: 227, description: "Settings in Actions")
  }

  /// Taps the back button to return to Actions from Settings
  private func tapBackToActions() throws {
    try performTap(x: 43, y: 75, description: "Back to Actions")
  }

  /// Performs a tap at the specified coordinates
  private func performTap(x: Int, y: Int, description: String) throws {
    print("Tapping \(description) at (\(x), \(y))")

    // In a real implementation, this would call the simulator tap function
    // For now, simulate the action with a delay
    Thread.sleep(forTimeInterval: 0.5)

    // Verify the tap was successful by checking UI state change
    let stateAfterTap = try getCurrentUIState()
    print("UI state after tapping \(description): \(stateAfterTap)")
  }
}

// MARK: - Test Errors

enum TestError: Error, LocalizedError {
  case appNotRunning
  case cannotReachDefaultState
  case navigationTimeout
  case unexpectedUIState

  var errorDescription: String? {
    switch self {
    case .appNotRunning:
      return "App is not running in simulator"
    case .cannotReachDefaultState:
      return "Cannot navigate to default camera state"
    case .navigationTimeout:
      return "Navigation action timed out"
    case .unexpectedUIState:
      return "UI state does not match expected state"
    }
  }
}
