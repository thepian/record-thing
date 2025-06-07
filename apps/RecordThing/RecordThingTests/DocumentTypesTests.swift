//
//  DocumentTypesTests.swift
//  RecordThingTests
//
//  Created by RecordThing on 2025-01-15.
//

import XCTest
import UniformTypeIdentifiers
@testable import RecordThing

class DocumentTypesTests: XCTestCase {
    
    func testCustomDocumentTypesRegistered() {
        // Test that our custom document types are properly registered
        
        // Evidence container type
        let evidenceType = UTType("com.thepia.recordthing.evidence")
        XCTAssertNotNil(evidenceType, "Evidence container type should be registered")
        XCTAssertEqual(evidenceType?.preferredFilenameExtension, "evidence")
        
        // Things container type
        let thingsType = UTType("com.thepia.recordthing.things")
        XCTAssertNotNil(thingsType, "Things container type should be registered")
        XCTAssertEqual(thingsType?.preferredFilenameExtension, "things")
    }
    
    func testStandardDocumentTypesSupported() {
        // Test that we support standard document types
        
        // SQLite databases
        let sqliteType = UTType.database
        XCTAssertTrue(sqliteType.conforms(to: .data))
        
        // Images
        let imageTypes = [UTType.jpeg, UTType.png, UTType.heif]
        for imageType in imageTypes {
            XCTAssertTrue(imageType.conforms(to: .image))
        }
        
        // Videos
        let videoTypes = [UTType.mpeg4Movie, UTType.quickTimeMovie]
        for videoType in videoTypes {
            XCTAssertTrue(videoType.conforms(to: .movie))
        }
        
        // Audio
        let audioTypes = [UTType.mp3, UTType.mpeg4Audio, UTType.wav]
        for audioType in audioTypes {
            XCTAssertTrue(audioType.conforms(to: .audio))
        }
    }
    
    func testDocumentTypeConformance() {
        // Test that our custom types conform to expected base types
        
        if let evidenceType = UTType("com.thepia.recordthing.evidence") {
            XCTAssertTrue(evidenceType.conforms(to: .data))
            XCTAssertTrue(evidenceType.conforms(to: UTType("public.composite-content")!))
        }
        
        if let thingsType = UTType("com.thepia.recordthing.things") {
            XCTAssertTrue(thingsType.conforms(to: .data))
            XCTAssertTrue(thingsType.conforms(to: UTType("public.composite-content")!))
        }
    }
    
    func testFileExtensionMapping() {
        // Test that file extensions map to correct types
        
        // Custom extensions
        XCTAssertEqual(UTType(filenameExtension: "evidence")?.identifier, "com.thepia.recordthing.evidence")
        XCTAssertEqual(UTType(filenameExtension: "things")?.identifier, "com.thepia.recordthing.things")
        
        // Standard extensions
        XCTAssertTrue(UTType(filenameExtension: "sqlite")?.conforms(to: .database) ?? false)
        XCTAssertTrue(UTType(filenameExtension: "jpg")?.conforms(to: .image) ?? false)
        XCTAssertTrue(UTType(filenameExtension: "mp4")?.conforms(to: .movie) ?? false)
        XCTAssertTrue(UTType(filenameExtension: "mp3")?.conforms(to: .audio) ?? false)
    }
    
    func testDocumentRoleConfiguration() {
        // Test that document roles are configured correctly
        
        // This would typically be tested by checking the app's Info.plist
        // or by testing actual document opening behavior
        
        let bundle = Bundle.main
        let documentTypes = bundle.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [[String: Any]]
        
        XCTAssertNotNil(documentTypes, "Document types should be configured in Info.plist")
        XCTAssertTrue(documentTypes?.count ?? 0 > 0, "Should have at least one document type configured")
        
        // Check for our custom types
        let hasEvidenceType = documentTypes?.contains { docType in
            let contentTypes = docType["LSItemContentTypes"] as? [String] ?? []
            return contentTypes.contains("com.thepia.recordthing.evidence")
        } ?? false
        
        let hasThingsType = documentTypes?.contains { docType in
            let contentTypes = docType["LSItemContentTypes"] as? [String] ?? []
            return contentTypes.contains("com.thepia.recordthing.things")
        } ?? false
        
        let hasSQLiteType = documentTypes?.contains { docType in
            let contentTypes = docType["LSItemContentTypes"] as? [String] ?? []
            return contentTypes.contains("public.sqlite3-database")
        } ?? false
        
        XCTAssertTrue(hasEvidenceType, "Should support evidence container type")
        XCTAssertTrue(hasThingsType, "Should support things container type")
        XCTAssertTrue(hasSQLiteType, "Should support SQLite database type")
    }
    
    func testExportedTypeDeclarations() {
        // Test that our exported type declarations are present
        
        let bundle = Bundle.main
        let exportedTypes = bundle.object(forInfoDictionaryKey: "UTExportedTypeDeclarations") as? [[String: Any]]
        
        XCTAssertNotNil(exportedTypes, "Exported type declarations should be present")
        
        let hasEvidenceExport = exportedTypes?.contains { typeDecl in
            let identifier = typeDecl["UTTypeIdentifier"] as? String
            return identifier == "com.thepia.recordthing.evidence"
        } ?? false
        
        let hasThingsExport = exportedTypes?.contains { typeDecl in
            let identifier = typeDecl["UTTypeIdentifier"] as? String
            return identifier == "com.thepia.recordthing.things"
        } ?? false
        
        XCTAssertTrue(hasEvidenceExport, "Should export evidence container type")
        XCTAssertTrue(hasThingsExport, "Should export things container type")
    }
    
    func testDocumentBrowserSupport() {
        // Test that document browser support is configured
        
        let bundle = Bundle.main
        let supportsDocumentBrowser = bundle.object(forInfoDictionaryKey: "UISupportsDocumentBrowser") as? Bool
        let supportsOpeningInPlace = bundle.object(forInfoDictionaryKey: "LSSupportsOpeningDocumentsInPlace") as? Bool
        
        #if os(iOS)
        XCTAssertEqual(supportsDocumentBrowser, true, "Should support document browser on iOS")
        #endif
        
        XCTAssertEqual(supportsOpeningInPlace, true, "Should support opening documents in place")
    }
    
    func testFileImportCapabilities() {
        // Test that the app can handle file imports
        
        // This would be tested with actual file import scenarios
        // For now, we test that the configuration supports it
        
        let supportedTypes = [
            "com.thepia.recordthing.evidence",
            "com.thepia.recordthing.things",
            "public.sqlite3-database",
            "public.image",
            "public.movie",
            "public.audio"
        ]
        
        for typeIdentifier in supportedTypes {
            let utType = UTType(typeIdentifier)
            XCTAssertNotNil(utType, "Should support type: \(typeIdentifier)")
        }
    }
}

// MARK: - Helper Extensions

extension DocumentTypesTests {
    
    /// Helper to check if a document type is configured for a specific role
    private func isDocumentTypeConfigured(for contentType: String, role: String) -> Bool {
        let bundle = Bundle.main
        let documentTypes = bundle.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [[String: Any]]
        
        return documentTypes?.contains { docType in
            let contentTypes = docType["LSItemContentTypes"] as? [String] ?? []
            let typeRole = docType["CFBundleTypeRole"] as? String ?? ""
            return contentTypes.contains(contentType) && typeRole == role
        } ?? false
    }
    
    /// Helper to get the description for an exported type
    private func getExportedTypeDescription(for identifier: String) -> String? {
        let bundle = Bundle.main
        let exportedTypes = bundle.object(forInfoDictionaryKey: "UTExportedTypeDeclarations") as? [[String: Any]]
        
        let typeDecl = exportedTypes?.first { typeDecl in
            let typeId = typeDecl["UTTypeIdentifier"] as? String
            return typeId == identifier
        }
        
        return typeDecl?["UTTypeDescription"] as? String
    }
}
