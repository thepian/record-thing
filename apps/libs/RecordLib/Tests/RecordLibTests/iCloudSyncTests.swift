//
//  iCloudSyncTests.swift
//  RecordLibTests
//
//  Created by Assistant on 07.06.2025.
//

import Combine
import Foundation
import XCTest

@testable import RecordLib

/// Comprehensive test suite for iCloud Documents syncing functionality
/// These tests verify real iCloud functionality and can be run on physical devices
@MainActor
final class iCloudSyncTests: XCTestCase {

  private var syncManager: iCloudSyncManager!
  private var cancellables: Set<AnyCancellable>!
  private var testDocumentsURL: URL!
  private var testFileManager: FileManager!

  override func setUp() async throws {
    try await super.setUp()

    syncManager = iCloudSyncManager.shared
    cancellables = Set<AnyCancellable>()
    testFileManager = FileManager.default

    // Create test documents directory
    testDocumentsURL = testFileManager.temporaryDirectory
      .appendingPathComponent("iCloudSyncTests")
      .appendingPathComponent(UUID().uuidString)

    try testFileManager.createDirectory(at: testDocumentsURL, withIntermediateDirectories: true)

    print("Test setup completed. Test directory: \(testDocumentsURL.path)")
  }

  override func tearDown() async throws {
    // Clean up test files
    try? testFileManager.removeItem(at: testDocumentsURL)

    cancellables?.removeAll()
    syncManager = nil

    try await super.tearDown()
  }

  // MARK: - Availability Tests

  func testICloudAvailability() async throws {
    // Test that we can detect iCloud availability
    let isAvailable = syncManager.isAvailable

    // On simulator, iCloud might not be available
    // On device with iCloud enabled, it should be available
    print("iCloud availability: \(isAvailable)")

    if isAvailable {
      XCTAssertNotNil(syncManager.iCloudContainerURL, "iCloud container URL should be available")
      XCTAssertNotNil(syncManager.iCloudDocumentsURL, "iCloud documents URL should be available")
    } else {
      print("⚠️ iCloud not available - this is expected on simulator or devices without iCloud")
    }
  }

  func testICloudContainerAccess() async throws {
    guard syncManager.isAvailable else {
      throw XCTSkip("iCloud not available - skipping container access test")
    }

    guard let containerURL = syncManager.iCloudContainerURL else {
      XCTFail("iCloud container URL should be available")
      return
    }

    // Test that we can access the container
    let containerExists = testFileManager.fileExists(atPath: containerURL.path)
    XCTAssertTrue(containerExists, "iCloud container should be accessible")

    // Test that we can create the Documents folder
    guard let documentsURL = syncManager.iCloudDocumentsURL else {
      XCTFail("iCloud documents URL should be available")
      return
    }

    try testFileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    let documentsExists = testFileManager.fileExists(atPath: documentsURL.path)
    XCTAssertTrue(documentsExists, "iCloud Documents folder should be created")
  }

  // MARK: - File Operations Tests

  func testCreateFileInICloud() async throws {
    guard syncManager.isAvailable else {
      throw XCTSkip("iCloud not available - skipping file creation test")
    }

    guard let documentsURL = syncManager.iCloudDocumentsURL else {
      XCTFail("iCloud documents URL should be available")
      return
    }

    // Create a test file
    let testFileName = "test-\(UUID().uuidString).txt"
    let testFileURL = documentsURL.appendingPathComponent(testFileName)
    let testContent = "Test content for iCloud sync verification"

    try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)

    // Verify file was created
    XCTAssertTrue(
      testFileManager.fileExists(atPath: testFileURL.path), "Test file should be created")

    // Wait for iCloud to process the file
    try await waitForICloudSync(fileURL: testFileURL, timeout: 30.0)

    // Verify file appears in document states
    let expectation = XCTestExpectation(description: "File appears in sync manager")

    syncManager.$documentStates
      .sink { states in
        if states.keys.contains(testFileName) {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    await fulfillment(of: [expectation], timeout: 10.0)

    // Clean up
    try? testFileManager.removeItem(at: testFileURL)
  }

  func testDatabaseSyncToICloud() async throws {
    guard syncManager.isAvailable else {
      throw XCTSkip("iCloud not available - skipping database sync test")
    }

    // Create a mock database file
    let localDatabaseURL = testDocumentsURL.appendingPathComponent("record-thing.sqlite")
    let testDatabaseContent = "Mock SQLite database content"

    try testDatabaseContent.write(to: localDatabaseURL, atomically: true, encoding: .utf8)

    // Enable sync
    syncManager.enableSync()

    // Perform manual sync
    await syncManager.performManualSync()

    // Check sync status
    XCTAssertEqual(syncManager.syncStatus, .completed, "Sync should complete successfully")
    XCTAssertNil(syncManager.syncError, "Sync should not have errors")

    // Verify database appears in iCloud
    guard let iCloudURL = syncManager.iCloudDocumentsURL else {
      XCTFail("iCloud documents URL should be available")
      return
    }

    let iCloudDatabaseURL = iCloudURL.appendingPathComponent("record-thing.sqlite")

    // Wait for file to appear in iCloud
    try await waitForFileToExist(at: iCloudDatabaseURL, timeout: 30.0)

    XCTAssertTrue(
      testFileManager.fileExists(atPath: iCloudDatabaseURL.path),
      "Database should be synced to iCloud")
  }

  // MARK: - Sync Status Tests

  func testSyncStatusUpdates() async throws {
    guard syncManager.isAvailable else {
      throw XCTSkip("iCloud not available - skipping sync status test")
    }

    var statusUpdates: [SyncStatus] = []

    let expectation = XCTestExpectation(description: "Sync status updates")
    expectation.expectedFulfillmentCount = 3  // idle -> syncing -> completed

    syncManager.$syncStatus
      .sink { status in
        statusUpdates.append(status)
        expectation.fulfill()
      }
      .store(in: &cancellables)

    // Enable sync and perform manual sync
    syncManager.enableSync()
    await syncManager.performManualSync()

    await fulfillment(of: [expectation], timeout: 30.0)

    // Verify we got the expected status progression
    XCTAssertTrue(statusUpdates.contains(.idle), "Should have idle status")
    XCTAssertTrue(statusUpdates.contains(.syncing), "Should have syncing status")
    XCTAssertTrue(
      statusUpdates.contains(.completed) || statusUpdates.contains(.failed),
      "Should have final status")
  }

  func testDocumentStateTracking() async throws {
    guard syncManager.isAvailable else {
      throw XCTSkip("iCloud not available - skipping document state test")
    }

    guard let documentsURL = syncManager.iCloudDocumentsURL else {
      XCTFail("iCloud documents URL should be available")
      return
    }

    // Create multiple test files
    let testFiles = ["test1.txt", "test2.txt", "test3.txt"]

    for fileName in testFiles {
      let fileURL = documentsURL.appendingPathComponent(fileName)
      try "Test content".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // Wait for files to be tracked
    let expectation = XCTestExpectation(description: "Document states updated")

    syncManager.$documentStates
      .sink { states in
        let trackedFiles = Set(states.keys)
        let expectedFiles = Set(testFiles)

        if expectedFiles.isSubset(of: trackedFiles) {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    await fulfillment(of: [expectation], timeout: 30.0)

    // Verify document states
    for fileName in testFiles {
      XCTAssertNotNil(
        syncManager.documentStates[fileName],
        "Document state should be tracked for \(fileName)")
    }

    // Clean up
    for fileName in testFiles {
      let fileURL = documentsURL.appendingPathComponent(fileName)
      try? testFileManager.removeItem(at: fileURL)
    }
  }

  // MARK: - Error Handling Tests

  func testSyncWithoutICloud() async throws {
    // This test simulates what happens when iCloud is not available
    // We can't easily disable iCloud programmatically, so we test the error paths

    if !syncManager.isAvailable {
      // Test that sync operations handle unavailable iCloud gracefully
      await syncManager.performManualSync()

      // Should complete without crashing, but may have errors
      XCTAssertTrue(
        syncManager.syncStatus == .failed || syncManager.syncStatus == .idle,
        "Sync should handle iCloud unavailability gracefully")
    }
  }

  // MARK: - Performance Tests

  func testSyncPerformance() async throws {
    guard syncManager.isAvailable else {
      throw XCTSkip("iCloud not available - skipping performance test")
    }

    // Measure sync performance
    let startTime = CFAbsoluteTimeGetCurrent()

    syncManager.enableSync()
    await syncManager.performManualSync()

    let syncTime = CFAbsoluteTimeGetCurrent() - startTime

    // Sync should complete within reasonable time (30 seconds)
    XCTAssertLessThan(syncTime, 30.0, "Sync should complete within 30 seconds")

    print("Sync completed in \(syncTime) seconds")
  }

  // MARK: - Helper Methods

  private func waitForICloudSync(fileURL: URL, timeout: TimeInterval) async throws {
    let startTime = Date()

    while Date().timeIntervalSince(startTime) < timeout {
      // Check if file has iCloud metadata
      do {
        let resourceValues = try fileURL.resourceValues(forKeys: [
          .ubiquitousItemDownloadingStatusKey,
          .ubiquitousItemIsDownloadedKey,
        ])

        if resourceValues.ubiquitousItemDownloadingStatus != nil {
          // File is being tracked by iCloud
          return
        }
      } catch {
        // File might not have iCloud metadata yet
      }

      try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
    }

    throw XCTError("Timeout waiting for iCloud sync")
  }

  private func waitForFileToExist(at url: URL, timeout: TimeInterval) async throws {
    let startTime = Date()

    while Date().timeIntervalSince(startTime) < timeout {
      if testFileManager.fileExists(atPath: url.path) {
        return
      }

      try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
    }

    throw XCTError("Timeout waiting for file to exist at \(url.path)")
  }
}

// MARK: - Test Error Types

private struct XCTError: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}

// MARK: - Mock Data Extensions

extension iCloudSyncTests {

  /// Creates mock database content for testing
  private func createMockDatabase() -> Data {
    // In a real implementation, this would create a minimal SQLite database
    return "Mock SQLite database".data(using: .utf8) ?? Data()
  }

  /// Creates mock asset files for testing
  private func createMockAssets() -> [String: Data] {
    return [
      "image1.jpg": "Mock JPEG data".data(using: .utf8) ?? Data(),
      "image2.png": "Mock PNG data".data(using: .utf8) ?? Data(),
      "video1.mp4": "Mock MP4 data".data(using: .utf8) ?? Data(),
    ]
  }
}
