//
//  Test.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 21.02.2025.
//

import Testing
import SwiftUI
import Blackbird
@testable import RecordLib

struct SFTViewTest {
    // Test model with various field types
    struct TestModel: BlackbirdModel {
        static var indexes: [[BlackbirdColumnKeyPath]] = [
            [ \.$title ]
        ]
        
        @BlackbirdColumn var id: Int
        @BlackbirdColumn var title: String
        @BlackbirdColumn var optional: String?
        @BlackbirdColumn var url: URL
        
        var nonColumn: String = "Non-column"
    }
    
    @Test func arrayHandling() throws {
        struct ArrayTest {
            let simpleArray = ["one", "two"]
            let complexArray = [["nested": "value"], ["nested": "value2"]]
        }
        
        let view = StructureFieldTableView("Test", fields: extractFields(ArrayTest()) )
        let fields = view.fields
        
        // Simple array should be flattened
        #expect(fields.contains { $0.label == "field.simpleArray" && $0.value == "one, two" })
        
        // Complex array should be nested
        #expect(fields.contains { $0.label == "field.complexArray" && $0.isNested && $0.value == "" })
        #expect(fields.contains { $0.label == "field.nested" && $0.value == "value" })
        #expect(fields.contains { $0.label == "field.nested" && $0.value == "value2" })
    }
    
    @Test func fieldExtraction() throws {
        let testModel = TestModel(id: 1, title: "Title", url: URL(filePath: "https://test.com")!)
        let view = StructureFieldTableView("Test", item: testModel)
        let fields = view.fields
        
        // Check basic field extraction
        #expect(fields.contains { $0.label == "field.id" && $0.value == "1" })
        #expect(fields.contains { $0.label == "field.title" && $0.value == "Title" })
        
        // TODO fix the nested render of URL type
        #expect(fields.contains { $0.label == "field.url" && $0.value.contains("test.com") })
        
        // Check optional handling
        #expect(fields.contains { $0.label == "field.optional" && $0.value == "nil" })
        
        // Check non-column property
        #expect(fields.contains { $0.label == "field.nonColumn" && $0.value == "Non-column" })
        
        // Check nested structure
//        #expect(fields.contains { $0.label == "nested" && $0.isNested })
    }
    
}
