//
//  SFTViewTest.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
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
    
    @Test func blackbirdColumnHandling() throws {
        let testItem = TestModel(id: 1, title: "Test", url: URL(string: "https://example.com")!)
        let view = RecordLib.StructureFieldTableView("Test", item: testItem)
        let fields = view.fields
        
        // BlackbirdColumn values should be unwrapped
        #expect(fields.contains { $0.label == "id" && $0.value == "1" })
        #expect(fields.contains { $0.label == "title" && $0.value == "Test" })
    }
    
    @Test func StructureFieldTableView() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
