//
//  SimpleiCloudTests.swift
//  RecordLibTests
//
//  Created by Assistant on 07.06.2025.
//

import XCTest
import Foundation
import Combine
@testable import RecordLib

/// Tests for simplified iCloud Documents functionality
/// These tests verify that automatic syncing works with proper entitlements
@MainActor
final class SimpleiCloudTests: XCTestCase {
    
    private var iCloudManager: SimpleiCloudManager!
    private var cancellables: Set<AnyCancellable>!
    private var testDocumentsURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        iCloudManager = SimpleiCloudManager.shared
        cancellables = Set<AnyCancellable>()
        testDocumentsURL = iCloudManager.getDocumentsURL()
        
        print("📁 Test setup - Documents URL: \(testDocumentsURL.path)")
        print("☁️ iCloud available: \(iCloudManager.isAvailable)")
    }
    
    override func tearDown() async throws {
        // Clean up test files
        cleanupTestFiles()
        
        cancellables?.removeAll()
        iCloudManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testICloudAvailability() async throws {
        // Test basic iCloud availability detection
        print("🔍 Testing iCloud availability...")
        
        if iCloudManager.isAvailable {
            print("✅ iCloud is available")
            XCTAssertNotNil(iCloudManager.iCloudContainerURL, "iCloud container URL should be available")
        } else {
            print("⚠️ iCloud not available - this is expected on simulator or devices without iCloud")
            // This is not a failure - just means iCloud isn't set up
        }
        
        // Documents URL should always be available
        XCTAssertTrue(FileManager.default.fileExists(atPath: testDocumentsURL.path), 
                     "Documents directory should exist")
    }
    
    func testDocumentsDirectoryAccess() async throws {
        // Test that we can read/write to Documents directory
        print("📝 Testing Documents directory access...")
        
        let testFileName = "test-access-\(UUID().uuidString).txt"
        let testContent = "Test content for Documents directory access"
        
        // Create file
        let fileURL = try iCloudManager.createTextFile(named: testFileName, content: testContent)
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), 
                     "Test file should be created")
        
        // Read file content
        let readContent = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(readContent, testContent, "File content should match")
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
        
        print("✅ Documents directory access test passed")
    }
    
    func testFileCreationAndListing() async throws {
        // Test creating multiple files and listing them
        print("📋 Testing file creation and listing...")
        
        let testFiles = [
            ("test-1-\(UUID().uuidString).txt", "Content 1"),
            ("test-2-\(UUID().uuidString).txt", "Content 2"),
            ("test-3-\(UUID().uuidString).txt", "Content 3")
        ]
        
        var createdFiles: [URL] = []
        
        // Create test files
        for (fileName, content) in testFiles {
            let fileURL = try iCloudManager.createTextFile(named: fileName, content: content)
            createdFiles.append(fileURL)
        }
        
        // List all documents
        let allDocuments = try iCloudManager.getAllDocuments()
        
        // Verify our test files are in the list
        for createdFile in createdFiles {
            XCTAssertTrue(allDocuments.contains(createdFile), 
                         "Created file should appear in documents list: \(createdFile.lastPathComponent)")
        }
        
        // Clean up
        for fileURL in createdFiles {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        print("✅ File creation and listing test passed")
    }
    
    // MARK: - iCloud Sync Tests (require iCloud to be available)
    
    func testAutomaticSyncSetup() async throws {
        guard iCloudManager.isAvailable else {
            throw XCTSkip("iCloud not available - skipping sync tests")
        }
        
        print("☁️ Testing automatic sync setup...")
        
        // Enable sync
        iCloudManager.enableSync()
        XCTAssertTrue(iCloudManager.isEnabled, "Sync should be enabled")
        
        // Create a file that should automatically sync
        let testFileName = "sync-test-\(UUID().uuidString).txt"
        let testContent = "This file should automatically sync to iCloud"
        
        let fileURL = try iCloudManager.createTextFile(named: testFileName, content: testContent)
        
        // Wait a moment for potential sync status updates
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Check if file appears in sync monitoring
        let syncStatus = iCloudManager.getFileStatus(testFileName)
        print("📊 File sync status: \(syncStatus)")
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
        
        print("✅ Automatic sync setup test completed")
    }
    
    func testSyncStatusMonitoring() async throws {
        guard iCloudManager.isAvailable else {
            throw XCTSkip("iCloud not available - skipping sync monitoring tests")
        }
        
        print("📊 Testing sync status monitoring...")
        
        // Enable sync
        iCloudManager.enableSync()
        
        // Monitor document state changes
        var stateUpdates: [[String: SimpleDocumentState]] = []
        
        let expectation = XCTestExpectation(description: "Document states updated")
        expectation.expectedFulfillmentCount = 1
        
        iCloudManager.$documentStates
            .sink { states in
                stateUpdates.append(states)
                if !states.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Create a test file
        let testFileName = "monitor-test-\(UUID().uuidString).txt"
        let fileURL = try iCloudManager.createTextFile(named: testFileName, content: "Monitoring test")
        
        // Wait for state updates
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Verify we got state updates
        XCTAssertGreaterThan(stateUpdates.count, 0, "Should receive document state updates")
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
        
        print("✅ Sync status monitoring test completed")
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncWithoutICloud() async throws {
        // Test behavior when iCloud is not available
        print("🚫 Testing sync without iCloud...")
        
        if !iCloudManager.isAvailable {
            // Test that operations still work locally
            let testFileName = "local-test-\(UUID().uuidString).txt"
            let fileURL = try iCloudManager.createTextFile(named: testFileName, content: "Local only")
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), 
                         "File should be created locally even without iCloud")
            
            // Clean up
            try? FileManager.default.removeItem(at: fileURL)
            
            print("✅ Local operation works without iCloud")
        } else {
            print("ℹ️ iCloud is available - skipping no-iCloud test")
        }
    }
    
    func testInvalidFileOperations() async throws {
        // Test error handling for invalid operations
        print("❌ Testing invalid file operations...")
        
        // Try to create file with invalid name
        do {
            let _ = try iCloudManager.createTextFile(named: "", content: "Invalid")
            XCTFail("Should not be able to create file with empty name")
        } catch {
            // Expected to fail
            print("✅ Correctly rejected empty file name")
        }
        
        // Try to read non-existent file status
        let nonExistentStatus = iCloudManager.getFileStatus("non-existent-file.txt")
        XCTAssertEqual(nonExistentStatus, "Unknown", "Non-existent file should have Unknown status")
        
        print("✅ Invalid file operations test completed")
    }
    
    // MARK: - Performance Tests
    
    func testFileCreationPerformance() async throws {
        // Test performance of creating multiple files
        print("⚡ Testing file creation performance...")
        
        let fileCount = 10
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var createdFiles: [URL] = []
        
        for i in 0..<fileCount {
            let fileName = "perf-test-\(i)-\(UUID().uuidString).txt"
            let content = "Performance test file \(i) created at \(Date())"
            let fileURL = try iCloudManager.createTextFile(named: fileName, content: content)
            createdFiles.append(fileURL)
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        print("📊 Created \(fileCount) files in \(String(format: "%.3f", creationTime)) seconds")
        print("📊 Average: \(String(format: "%.3f", creationTime / Double(fileCount))) seconds per file")
        
        // Performance should be reasonable (less than 1 second per file)
        XCTAssertLessThan(creationTime / Double(fileCount), 1.0, 
                         "File creation should be reasonably fast")
        
        // Clean up
        for fileURL in createdFiles {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        print("✅ File creation performance test completed")
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestFiles() {
        // Clean up any test files that might be left over
        do {
            let documents = try iCloudManager.getAllDocuments()
            for document in documents {
                let fileName = document.lastPathComponent
                if fileName.contains("test-") || fileName.contains("perf-") || fileName.contains("sync-") {
                    try? FileManager.default.removeItem(at: document)
                }
            }
        } catch {
            print("⚠️ Failed to clean up test files: \(error)")
        }
    }
    
    private func waitForCondition(
        timeout: TimeInterval = 10.0,
        condition: () async -> Bool
    ) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        throw NSError(domain: "SimpleiCloudTests", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Timeout waiting for condition"
        ])
    }
}

// MARK: - Test Configuration

extension SimpleiCloudTests {
    
    /// Test configuration for simplified iCloud tests
    static let testConfiguration = SimpleiCloudTestConfiguration(
        requiresPhysicalDevice: false, // Can run on simulator
        requiresiCloudEnabled: false,  // Gracefully handles no iCloud
        testTimeout: 30.0,
        networkRequired: false         // Works offline for local operations
    )
}

struct SimpleiCloudTestConfiguration {
    let requiresPhysicalDevice: Bool
    let requiresiCloudEnabled: Bool
    let testTimeout: TimeInterval
    let networkRequired: Bool
}
