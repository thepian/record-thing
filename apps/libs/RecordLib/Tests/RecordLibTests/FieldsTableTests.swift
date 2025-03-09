import Testing
import SwiftUI
@testable import RecordLib

struct FieldsTableTests {
    
    /*
    @Test func basicFieldsRendering() throws {
        let fields = [
            FieldItem(label: "Name", value: "John Doe", type: "String"),
            FieldItem(label: "Age", value: 42, type: "Int"),
            FieldItem(label: "Active", value: true, type: "Bool")
        ]
        
        let view = FieldsTable(
            rightAlignValues: false,
            fieldColumnName: "Descriptions",
            valueColumnName: "Values",
            maxLines: 10,
            fields: fields
        )
        
        // Test view hierarchy
        let table = try view.inspect().find(viewWithId: "fieldsTable"))
        
        // Test column headers
        #expect(try table.find(text: "Field").string() == "Field")
        #expect(try table.find(text: "Value").string() == "Value")
        
        // Test field rows
        #expect(try table.find(text: "Name").string() == "Name")
        #expect(try table.find(text: "John Doe").string() == "John Doe")
        #expect(try table.find(text: "Age").string() == "Age")
        #expect(try table.find(text: "42").string() == "42")
        #expect(try table.find(text: "Active").string() == "Active")
        #expect(try table.find(text: "true").string() == "true")
    }
    
    @Test func nestedFieldsRendering() throws {
        let fields = [
            FieldItem(label: "User", value: "", type: "Struct", isNested: true),
            FieldItem(label: "name", value: "John", type: "String", indent: 1),
            FieldItem(label: "Address", value: "", type: "Struct", indent: 1, isNested: true),
            FieldItem(label: "street", value: "123 Main St", type: "String", indent: 2)
        ]
        
        let view = FieldsTable(
            rightAlignValues: false,
            fieldColumnName: "Property",
            valueColumnName: "Data",
            maxLines: 10,
            fields: fields
        )
        
        // Test view hierarchy
        let table = try view.find(viewWithId: "fieldsTable"))
        
        // Test custom column headers
        #expect(try table.find(text: "Property").string() == "Property")
        #expect(try table.find(text: "Data").string() == "Data")
        
        // Test nested structure
        #expect(try table.find(text: "User").string() == "User")
        #expect(try table.find(text: "name").string() == "name")
        #expect(try table.find(text: "John").string() == "John")
        #expect(try table.find(text: "Address").string() == "Address")
        #expect(try table.find(text: "street").string() == "street")
        #expect(try table.find(text: "123 Main St").string() == "123 Main St")
    }
    
    @Test func emptyFieldsHandling() throws {
        let view = FieldsTable(
            rightAlignValues: false,
            fieldColumnName: "Property",
            valueColumnName: "Data",
            maxLines: 10,
            fields: []

        )
        
        // Test empty state
        let table = try view.inspect().find(viewWithId: "fieldsTable"))
        #expect(try table.find(text: "No fields available").exists)
    }
     
     */
}
