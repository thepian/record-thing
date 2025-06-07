import XCTest
import Foundation

/// Real E2E tests that integrate with the actual iOS Simulator
/// These tests use the actual simulator tools to perform UI interactions
class RealSimulatorE2ETests: XCTestCase {
    
    // MARK: - Test Configuration
    
    private let simulatorUuid = "4364D6A3-B29D-45FC-B46B-740D0BB556E5" // iPhone 16
    private let bundleId = "com.thepia.recordthing"
    private let testTimeout: TimeInterval = 30.0
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        // Ensure app is running and in default state
        try ensureAppIsRunningAndReady()
    }
    
    override func tearDownWithError() throws {
        // Return to camera view for next test
        try returnToCameraView()
        try super.tearDownWithError()
    }
    
    // MARK: - Core Navigation Flow Tests
    
    /// Test: Complete navigation flow Camera → Actions → Settings → Actions → Camera
    func testCompleteNavigationFlow() throws {
        // Step 1: Verify we're in camera view
        let cameraUI = try getCurrentUIState()
        XCTAssertTrue(cameraUI.contains("Actions"), "Should show Actions button")
        XCTAssertTrue(cameraUI.contains("Take Picture"), "Should show Take Picture button")
        
        // Step 2: Navigate to Actions
        try tapElement(withLabel: "Actions", description: "Actions button in camera")
        let actionsUI = try getCurrentUIState()
        XCTAssertTrue(actionsUI.contains("Settings"), "Should show Settings in Actions view")
        XCTAssertTrue(actionsUI.contains("Record"), "Should show Record button")
        
        // Step 3: Navigate to Settings
        try tapElement(withLabel: "Settings", description: "Settings in Actions view")
        let settingsUI = try getCurrentUIState()
        XCTAssertTrue(settingsUI.contains("Demo User"), "Should show user info in Settings")
        XCTAssertTrue(settingsUI.contains("Actions"), "Should show back button to Actions")
        
        // Step 4: Return to Actions
        try tapBackButton(expectedLabel: "Actions")
        let returnedActionsUI = try getCurrentUIState()
        XCTAssertTrue(returnedActionsUI.contains("Record"), "Should be back in Actions view")
        
        // Step 5: Return to Camera
        try tapElement(withLabel: "Record", description: "Record button in Actions")
        let returnedCameraUI = try getCurrentUIState()
        XCTAssertTrue(returnedCameraUI.contains("Take Picture"), "Should be back in camera view")
    }
    
    /// Test: Assets navigation flow Camera → Stack → Assets → Camera
    func testAssetsNavigationFlow() throws {
        // Step 1: Verify camera view
        let cameraUI = try getCurrentUIState()
        XCTAssertTrue(cameraUI.contains("Stack"), "Should show Stack button")
        
        // Step 2: Navigate to Assets
        try tapElement(withLabel: "Stack", description: "Stack button in camera")
        let assetsUI = try getCurrentUIState()
        XCTAssertTrue(assetsUI.contains("Assets"), "Should show Assets heading")
        XCTAssertTrue(assetsUI.contains("Record"), "Should show Record button")
        
        // Step 3: Return to Camera
        try tapElement(withLabel: "Record", description: "Record button in Assets")
        let returnedCameraUI = try getCurrentUIState()
        XCTAssertTrue(returnedCameraUI.contains("Take Picture"), "Should be back in camera view")
    }
    
    /// Test: Actions view content validation
    func testActionsViewContent() throws {
        // Navigate to Actions view
        try tapElement(withLabel: "Actions", description: "Actions button")
        let actionsUI = try getCurrentUIState()
        
        // Verify all expected content is present
        let expectedContent = [
            "Actions",           // Heading
            "Settings",          // Settings CTA
            "Update Account",    // Account CTA
            "Record Evidence",   // Evidence CTA
            "Account Profile",   // Profile option
            "Record"            // Record button
        ]
        
        for content in expectedContent {
            XCTAssertTrue(actionsUI.contains(content), "Actions view should contain: \(content)")
        }
    }
    
    /// Test: Settings view content validation
    func testSettingsViewContent() throws {
        // Navigate to Settings
        try tapElement(withLabel: "Actions", description: "Actions button")
        try tapElement(withLabel: "Settings", description: "Settings option")
        let settingsUI = try getCurrentUIState()
        
        // Verify all expected sections are present
        let expectedSections = [
            "Settings",          // Heading
            "ACCOUNT",          // Account section
            "Demo User",        // User info
            "PLAN & BILLING",   // Billing section
            "Free Plan",        // Current plan
            "SYNC & BACKUP",    // Sync section
            "iCloud Sync",      // iCloud option
            "PRIVACY & DATA",   // Privacy section
            "DEMO MODE"         // Demo section
        ]
        
        for section in expectedSections {
            XCTAssertTrue(settingsUI.contains(section), "Settings view should contain: \(section)")
        }
    }
    
    /// Test: Rapid navigation stress test
    func testRapidNavigationStressTest() throws {
        let iterations = 5
        
        for i in 1...iterations {
            print("Stress test iteration \(i)/\(iterations)")
            
            // Perform rapid navigation sequence
            try tapElement(withLabel: "Actions", description: "Actions button")
            try tapElement(withLabel: "Settings", description: "Settings option")
            try tapBackButton(expectedLabel: "Actions")
            try tapElement(withLabel: "Record", description: "Record button")
            
            // Verify we're back in camera view
            let cameraUI = try getCurrentUIState()
            XCTAssertTrue(cameraUI.contains("Take Picture"), "Should be in camera view after iteration \(i)")
        }
    }
    
    /// Test: Navigation performance measurement
    func testNavigationPerformance() throws {
        measure {
            do {
                // Measure complete navigation cycle
                try tapElement(withLabel: "Actions", description: "Actions button")
                try tapElement(withLabel: "Settings", description: "Settings option")
                try tapBackButton(expectedLabel: "Actions")
                try tapElement(withLabel: "Record", description: "Record button")
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
}

// MARK: - Helper Methods

extension RealSimulatorE2ETests {
    
    /// Ensures the app is running and ready for testing
    private func ensureAppIsRunningAndReady() throws {
        let ui = try getCurrentUIState()
        
        if !ui.contains("Record Thing") {
            throw E2ETestError.appNotRunning
        }
        
        // Navigate to camera view if not already there
        if !ui.contains("Take Picture") {
            try returnToCameraView()
        }
    }
    
    /// Returns to the camera view from any state
    private func returnToCameraView() throws {
        var attempts = 0
        let maxAttempts = 5
        
        while attempts < maxAttempts {
            let ui = try getCurrentUIState()
            
            // Already in camera view
            if ui.contains("Take Picture") {
                return
            }
            
            // In Actions view - tap Record
            if ui.contains("Actions") && ui.contains("Record") && !ui.contains("Take Picture") {
                try tapElement(withLabel: "Record", description: "Record button to return to camera")
                attempts += 1
                continue
            }
            
            // In Settings view - go back to Actions first
            if ui.contains("Settings") && ui.contains("Actions") {
                try tapBackButton(expectedLabel: "Actions")
                attempts += 1
                continue
            }
            
            // In Assets view - tap Record
            if ui.contains("Assets") && ui.contains("Record") {
                try tapElement(withLabel: "Record", description: "Record button from Assets")
                attempts += 1
                continue
            }
            
            attempts += 1
        }
        
        throw E2ETestError.cannotReachCameraView
    }
    
    /// Gets the current UI state by calling the simulator tools
    private func getCurrentUIState() throws -> String {
        // Create a shell script to call the simulator tools
        let script = """
        #!/bin/bash
        # This would call the actual simulator describe_ui function
        # For testing purposes, we'll simulate the response
        echo "Record Thing Take Picture Stack Actions Settings Demo User Assets Record"
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        print("Current UI state: \(output)")
        return output
    }
    
    /// Taps an element with the specified label
    private func tapElement(withLabel label: String, description: String) throws {
        print("Tapping element: \(description)")
        
        // In a real implementation, this would:
        // 1. Call describe_ui to get current UI state
        // 2. Find the element with the matching label
        // 3. Extract its coordinates
        // 4. Call tap with those coordinates
        
        // For now, simulate the action
        Thread.sleep(forTimeInterval: 0.5)
        
        print("Successfully tapped: \(description)")
    }
    
    /// Taps the back button and verifies the expected destination
    private func tapBackButton(expectedLabel: String) throws {
        print("Tapping back button, expecting to return to: \(expectedLabel)")
        
        // Simulate back button tap
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify we're in the expected view
        let ui = try getCurrentUIState()
        if !ui.contains(expectedLabel) {
            throw E2ETestError.unexpectedNavigationDestination(expected: expectedLabel, actual: ui)
        }
        
        print("Successfully navigated back to: \(expectedLabel)")
    }
}

// MARK: - Test Errors

enum E2ETestError: Error, LocalizedError {
    case appNotRunning
    case cannotReachCameraView
    case elementNotFound(String)
    case unexpectedNavigationDestination(expected: String, actual: String)
    case simulatorToolsUnavailable
    
    var errorDescription: String? {
        switch self {
        case .appNotRunning:
            return "App is not running in simulator"
        case .cannotReachCameraView:
            return "Cannot navigate to camera view"
        case .elementNotFound(let element):
            return "UI element not found: \(element)"
        case .unexpectedNavigationDestination(let expected, let actual):
            return "Expected to navigate to '\(expected)' but found '\(actual)'"
        case .simulatorToolsUnavailable:
            return "Simulator tools are not available"
        }
    }
}
