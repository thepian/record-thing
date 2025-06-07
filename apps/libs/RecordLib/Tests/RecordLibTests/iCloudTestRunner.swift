//
//  iCloudTestRunner.swift
//  RecordLibTests
//
//  Created by Assistant on 07.06.2025.
//

import XCTest
import Foundation
@testable import RecordLib

/// Test runner that provides utilities for running iCloud sync tests
/// Includes environment detection and test configuration
final class iCloudTestRunner: NSObject {
    
    static let shared = iCloudTestRunner()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Environment Detection
    
    /// Checks if the current environment supports iCloud testing
    static func canRunICloudTests() -> Bool {
        let syncManager = iCloudSyncManager.shared
        
        // Check basic iCloud availability
        guard syncManager.isAvailable else {
            print("❌ iCloud not available - tests will be skipped")
            return false
        }
        
        // Check if running on simulator
        #if targetEnvironment(simulator)
        print("⚠️ Running on simulator - some iCloud features may be limited")
        return true // Allow tests but with warnings
        #else
        print("✅ Running on physical device - full iCloud testing available")
        return true
        #endif
    }
    
    /// Provides detailed environment information for test reporting
    static func getTestEnvironmentInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        // Device information
        #if os(iOS)
        info["device_model"] = UIDevice.current.model
        info["device_name"] = UIDevice.current.name
        info["system_version"] = UIDevice.current.systemVersion
        info["is_simulator"] = TARGET_OS_SIMULATOR == 1
        #endif
        
        // iCloud information
        let syncManager = iCloudSyncManager.shared
        info["icloud_available"] = syncManager.isAvailable
        info["icloud_container_url"] = syncManager.iCloudContainerURL?.path
        info["icloud_documents_url"] = syncManager.iCloudDocumentsURL?.path
        
        // Test configuration
        info["test_timeout"] = 60.0
        info["test_timestamp"] = Date().timeIntervalSince1970
        
        return info
    }
    
    // MARK: - Test Utilities
    
    /// Creates a test file with unique content for testing
    static func createTestFile(name: String, in directory: URL) throws -> URL {
        let fileURL = directory.appendingPathComponent(name)
        let content = """
        Test File: \(name)
        Created: \(Date())
        UUID: \(UUID().uuidString)
        Environment: \(getTestEnvironmentInfo())
        """
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    /// Waits for a condition to be met with timeout
    static func waitForCondition(
        timeout: TimeInterval = 30.0,
        pollingInterval: TimeInterval = 0.5,
        condition: () async throws -> Bool
    ) async throws {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if try await condition() {
                return
            }
            
            try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
        }
        
        throw NSError(domain: "iCloudTestRunner", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Timeout waiting for condition"
        ])
    }
    
    /// Generates a unique test identifier
    static func generateTestID() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "test-\(timestamp)-\(uuid)"
    }
    
    // MARK: - Test Reporting
    
    /// Logs test results in a structured format
    static func logTestResult(
        testName: String,
        success: Bool,
        duration: TimeInterval,
        details: [String: Any] = [:]
    ) {
        let status = success ? "✅ PASS" : "❌ FAIL"
        let durationString = String(format: "%.2fs", duration)
        
        print("\n" + "="*60)
        print("\(status) \(testName)")
        print("Duration: \(durationString)")
        
        if !details.isEmpty {
            print("Details:")
            for (key, value) in details {
                print("  \(key): \(value)")
            }
        }
        
        print("="*60 + "\n")
    }
    
    /// Creates a test report summary
    static func createTestReport(results: [TestResult]) -> String {
        let totalTests = results.count
        let passedTests = results.filter { $0.success }.count
        let failedTests = totalTests - passedTests
        let totalDuration = results.reduce(0) { $0 + $1.duration }
        
        let report = """
        
        📊 iCloud Sync Test Report
        ========================
        
        Environment: \(getTestEnvironmentInfo())
        
        Results:
        - Total Tests: \(totalTests)
        - Passed: \(passedTests)
        - Failed: \(failedTests)
        - Success Rate: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%
        - Total Duration: \(String(format: "%.2f", totalDuration))s
        
        Test Details:
        \(results.map { "- \($0.name): \($0.success ? "PASS" : "FAIL") (\(String(format: "%.2f", $0.duration))s)" }.joined(separator: "\n"))
        
        Generated: \(Date())
        """
        
        return report
    }
}

// MARK: - Supporting Types

struct TestResult {
    let name: String
    let success: Bool
    let duration: TimeInterval
    let details: [String: Any]
    
    init(name: String, success: Bool, duration: TimeInterval, details: [String: Any] = [:]) {
        self.name = name
        self.success = success
        self.duration = duration
        self.details = details
    }
}

// MARK: - Test Execution Helper

/// Helper class for executing iCloud tests with proper setup and teardown
class iCloudTestExecutor {
    
    private var testResults: [TestResult] = []
    
    func executeTest<T>(
        name: String,
        test: () async throws -> T
    ) async -> TestResult {
        let startTime = Date()
        
        do {
            _ = try await test()
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(name: name, success: true, duration: duration)
            testResults.append(result)
            
            iCloudTestRunner.logTestResult(
                testName: name,
                success: true,
                duration: duration
            )
            
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let result = TestResult(
                name: name,
                success: false,
                duration: duration,
                details: ["error": error.localizedDescription]
            )
            testResults.append(result)
            
            iCloudTestRunner.logTestResult(
                testName: name,
                success: false,
                duration: duration,
                details: ["error": error.localizedDescription]
            )
            
            return result
        }
    }
    
    func generateReport() -> String {
        return iCloudTestRunner.createTestReport(results: testResults)
    }
    
    func clearResults() {
        testResults.removeAll()
    }
}

// MARK: - Test Configuration

/// Configuration for iCloud sync tests
struct iCloudSyncTestConfig {
    static let defaultTimeout: TimeInterval = 60.0
    static let shortTimeout: TimeInterval = 30.0
    static let longTimeout: TimeInterval = 120.0
    
    static let pollingInterval: TimeInterval = 0.5
    static let maxRetries: Int = 3
    
    static let testFilePrefix = "icloud-test"
    static let testDatabaseName = "test-record-thing.sqlite"
    
    /// Returns configuration appropriate for the current environment
    static func forCurrentEnvironment() -> iCloudSyncTestConfig {
        return iCloudSyncTestConfig()
    }
}

// MARK: - Mock Data Generators

extension iCloudTestRunner {
    
    /// Generates mock database content for testing
    static func generateMockDatabase() -> String {
        return """
        -- Mock SQLite Database for iCloud Sync Testing
        -- Generated: \(Date())
        -- Test ID: \(generateTestID())
        
        PRAGMA foreign_keys=OFF;
        BEGIN TRANSACTION;
        
        CREATE TABLE test_evidence (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            device_id TEXT
        );
        
        INSERT INTO test_evidence VALUES(1,'Test Evidence 1','Mock evidence content','\(Date())','test-device');
        INSERT INTO test_evidence VALUES(2,'Test Evidence 2','Another mock evidence','\(Date())','test-device');
        
        CREATE TABLE test_sync_metadata (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        INSERT INTO test_sync_metadata VALUES('last_sync','\(Date())','\(Date())');
        INSERT INTO test_sync_metadata VALUES('device_id','test-device','\(Date())');
        
        COMMIT;
        """
    }
    
    /// Generates mock asset files for testing
    static func generateMockAssets() -> [String: Data] {
        let testID = generateTestID()
        
        return [
            "image-\(testID).jpg": "Mock JPEG image data for testing".data(using: .utf8) ?? Data(),
            "video-\(testID).mp4": "Mock MP4 video data for testing".data(using: .utf8) ?? Data(),
            "audio-\(testID).m4a": "Mock M4A audio data for testing".data(using: .utf8) ?? Data(),
            "document-\(testID).pdf": "Mock PDF document data for testing".data(using: .utf8) ?? Data()
        ]
    }
}
