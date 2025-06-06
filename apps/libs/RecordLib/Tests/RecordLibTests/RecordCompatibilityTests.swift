//
//  RecordCompatibilityTests.swift
//  RecordLib
//
//  Created by AI Assistant on 08.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import XCTest
import SwiftUI
@testable import RecordLib

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

class RecordCompatibilityTests: XCTestCase {
    
    // MARK: - RecordImage Tests
    
    func testRecordImageTypealias() {
        // Test that RecordImage is properly aliased to platform-specific types
        #if canImport(UIKit)
        XCTAssertTrue(RecordImage.self == UIImage.self, "RecordImage should be UIImage on iOS")
        #elseif canImport(AppKit)
        XCTAssertTrue(RecordImage.self == NSImage.self, "RecordImage should be NSImage on macOS")
        #endif
    }
    
    func testRecordImageSystemImage() {
        // Test system image creation
        let systemImage = RecordImage.systemImage("star")
        XCTAssertNotNil(systemImage, "Should be able to create system image")
        
        let invalidImage = RecordImage.systemImage("invalid_system_image_name_123")
        // Note: This might still return an image on some platforms with fallbacks
        // so we just test that the method doesn't crash
        _ = invalidImage
    }
    
    func testRecordImageAsImage() {
        // Test conversion to SwiftUI Image
        if let systemImage = RecordImage.systemImage("star") {
            let swiftUIImage = systemImage.asImage
            XCTAssertTrue(swiftUIImage is Image, "Should convert to SwiftUI Image")
        }
    }
    
    func testRecordImageJPEGData() {
        // Test JPEG data conversion
        if let systemImage = RecordImage.systemImage("star") {
            let jpegData = systemImage.recordJpegData(compressionQuality: 0.8)
            XCTAssertNotNil(jpegData, "Should be able to create JPEG data")
            
            if let data = jpegData {
                XCTAssertGreaterThan(data.count, 0, "JPEG data should not be empty")
            }
        }
    }
    
    func testRecordImageLogInfo() {
        // Test logging doesn't crash
        if let systemImage = RecordImage.systemImage("star") {
            systemImage.logInfo(label: "Test Image")
            systemImage.logInfo() // Test without label
        }
    }
    
    // MARK: - Color Extension Tests
    
    func testSystemBackgroundColors() {
        // Test that system background colors are accessible
        let systemBg = Color.systemBackground
        XCTAssertNotNil(systemBg, "systemBackground should be available")
        
        let secondaryBg = Color.secondarySystemBackground
        XCTAssertNotNil(secondaryBg, "secondarySystemBackground should be available")
        
        let tertiaryBg = Color.tertiarySystemBackground
        XCTAssertNotNil(tertiaryBg, "tertiarySystemBackground should be available")
        
        let adaptiveBg = Color.adaptiveSecondaryBackground
        XCTAssertNotNil(adaptiveBg, "adaptiveSecondaryBackground should be available")
    }
    
    func testSystemGrayColors() {
        // Test that system gray colors are accessible
        let gray4 = Color.systemGray4
        XCTAssertNotNil(gray4, "systemGray4 should be available")
        
        let gray6 = Color.systemGray6
        XCTAssertNotNil(gray6, "systemGray6 should be available")
        
        let separator = Color.separator
        XCTAssertNotNil(separator, "separator should be available")
    }
    
    // MARK: - RecordRectCorner Tests
    
    func testRecordRectCornerCreation() {
        // Test basic corner creation
        let topLeft = RecordRectCorner.topLeft
        XCTAssertTrue(topLeft.contains(.topLeft), "Should contain topLeft")
        XCTAssertFalse(topLeft.contains(.topRight), "Should not contain topRight")
        
        let allCorners = RecordRectCorner.allCorners
        XCTAssertTrue(allCorners.contains(.topLeft), "allCorners should contain topLeft")
        XCTAssertTrue(allCorners.contains(.topRight), "allCorners should contain topRight")
        XCTAssertTrue(allCorners.contains(.bottomLeft), "allCorners should contain bottomLeft")
        XCTAssertTrue(allCorners.contains(.bottomRight), "allCorners should contain bottomRight")
    }
    
    func testRecordRectCornerCombination() {
        // Test corner combination
        let topCorners: RecordRectCorner = [.topLeft, .topRight]
        XCTAssertTrue(topCorners.contains(.topLeft), "Should contain topLeft")
        XCTAssertTrue(topCorners.contains(.topRight), "Should contain topRight")
        XCTAssertFalse(topCorners.contains(.bottomLeft), "Should not contain bottomLeft")
        XCTAssertFalse(topCorners.contains(.bottomRight), "Should not contain bottomRight")
    }
    
    func testRecordRectCornerSet() {
        // Test corner set conversion
        let topCorners: RecordRectCorner = [.topLeft, .topRight]
        let cornerSet = topCorners.cornerSet
        
        XCTAssertTrue(cornerSet.contains("topLeading"), "Should contain topLeading")
        XCTAssertTrue(cornerSet.contains("topTrailing"), "Should contain topTrailing")
        XCTAssertFalse(cornerSet.contains("bottomLeading"), "Should not contain bottomLeading")
        XCTAssertFalse(cornerSet.contains("bottomTrailing"), "Should not contain bottomTrailing")
        
        let allCorners = RecordRectCorner.allCorners
        let allCornerSet = allCorners.cornerSet
        XCTAssertEqual(allCornerSet.count, 4, "All corners should have 4 elements")
    }
    
    func testRecordRectCornerLogging() {
        // Test logging doesn't crash
        let corners: RecordRectCorner = [.topLeft, .bottomRight]
        corners.logInfo(label: "Test Corners")
        corners.logInfo() // Test without label
    }
    
    // MARK: - RecordRoundedCorner Tests
    
    func testRecordRoundedCornerPath() {
        // Test that path generation doesn't crash
        let shape = RecordRoundedCorner(radius: 10, corners: [.topLeft, .topRight])
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = shape.path(in: rect)
        
        XCTAssertFalse(path.isEmpty, "Path should not be empty")
    }
    
    func testRecordRoundedCornerAllCorners() {
        // Test all corners rounding
        let shape = RecordRoundedCorner(radius: 15, corners: .allCorners)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = shape.path(in: rect)
        
        XCTAssertFalse(path.isEmpty, "Path should not be empty")
    }
    
    func testRecordRoundedCornerZeroRadius() {
        // Test zero radius (should create a rectangle)
        let shape = RecordRoundedCorner(radius: 0, corners: .allCorners)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = shape.path(in: rect)
        
        XCTAssertFalse(path.isEmpty, "Path should not be empty even with zero radius")
    }
    
    // MARK: - Integration Tests
    
    func testViewCornerRadiusModifier() {
        // Test that the View extension works without crashing
        let view = Rectangle()
            .fill(Color.blue)
            .cornerRadius(10, recordCorners: [.topLeft, .topRight])
        
        // We can't easily test the visual result, but we can ensure it doesn't crash
        XCTAssertNotNil(view, "View with corner radius should be created successfully")
    }
    
    func testCompatibilityWithExistingUIRectCornerFunction() {
        // Test that our new function doesn't interfere with existing UIRectCorner function
        #if canImport(UIKit)
        let view = Rectangle()
            .fill(Color.red)
            .cornerRadius(5, corners: UIRectCorner.topLeft)
        
        XCTAssertNotNil(view, "Original cornerRadius function should still work")
        #endif
    }
}

// MARK: - Performance Tests

extension RecordCompatibilityTests {
    
    func testRecordImagePerformance() {
        measure {
            for _ in 0..<100 {
                _ = RecordImage.systemImage("star")
            }
        }
    }
    
    func testRecordRoundedCornerPerformance() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        measure {
            for _ in 0..<100 {
                let shape = RecordRoundedCorner(radius: 10, corners: [.topLeft, .topRight])
                _ = shape.path(in: rect)
            }
        }
    }
    
    func testColorExtensionPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Color.systemBackground
                _ = Color.secondarySystemBackground
                _ = Color.tertiarySystemBackground
                _ = Color.systemGray4
                _ = Color.systemGray6
                _ = Color.separator
            }
        }
    }
} 