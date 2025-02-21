import Testing
import Foundation
@testable import RecordLib

struct FieldItemEncoderTests {
    // Test model with various field types
    struct TestStruct: Encodable {
        let string: String
        let int: Int
        let double: Double
        let float: Float
        let bool: Bool
        let date: Date
        let optional: String?
        let array: [String]
        
        enum TestEnum: String, Encodable {
            case one
            case two
        }
        let enumValue: TestEnum
    }
    
    @Test func basicTypeEncoding() throws {
        let date = Date(timeIntervalSince1970: 0)
        let testData = TestStruct(
            string: "test",
            int: 42,
            double: 3.14,
            float: 2.71,
            bool: true,
            date: date,
            optional: "has value", // nil optional values are skipped
            array: ["one", "two"],
            enumValue: .one
        )
        
        var fields: [FieldItem] = []
        let encoder = FieldItemEncoder { field in
            fields.append(field)
        }
        try testData.encode(to: encoder)
        
        // Test basic types
        #expect(fields.count == 9)
        #expect(fields.contains { $0.label == "field.string" && $0.value == "test" && $0.type == "String" && $0.indent == 0 })
        #expect(fields.contains { $0.label == "field.int" && $0.value == "42" && $0.type == "Int" })
        #expect(fields.contains { $0.label == "field.double" && $0.value == "3.14" && $0.type == "Double" })
        #expect(fields.contains { $0.label == "field.float" && $0.value == "2.71" && $0.type == "Float" })
        #expect(fields.contains { $0.label == "field.bool" && $0.value == "true" && $0.type == "Bool" })
        #expect(fields.contains { $0.label == "field.date" && $0.value.contains("1970") && $0.type == "Date" })
        
        // Test optional
        #expect(fields.contains { $0.label == "field.optional" && $0.value == "has value" && $0.type == "String" })
        
        // Test array
        #expect(fields.contains { $0.label == "field.array" && $0.value == "one, two" })
        
        // Test enum
        #expect(fields.contains { $0.label == "field.enumValue" && $0.value == "one" && $0.type == "TestEnum" })
    }
    
    @Test func arrayEncoding() throws {
        struct ArrayTest: Encodable {
            let simpleArray = ["one", "two"]
            let complexArrayArray = [["nested", "value"], ["multi", "value2"]]
        }
        
        var fields: [FieldItem] = []
        let encoder = FieldItemEncoder { field in
            fields.append(field)
        }
        try ArrayTest().encode(to: encoder)
        
        // Test simple array
        #expect(fields.contains { $0.label == "field.simpleArray" && $0.value == "one, two" && $0.type == "Array<String>" })
        
        // Test complex array
        #expect(fields.contains { $0.label == "field.complexArrayArray" && $0.isNested && $0.type == "Array" && $0.indent == 0 })
//        #expect(fields.contains { $0.label == "field.nested"})
    }
    
    @Test func entityWithAddress() throws {
        struct Nested: Encodable {
            struct Address : Encodable {
                let street = "123 Main St"
                let city = "Springfield"
                let country = "USA"
            }
            
            let id: String = "123"
            let name: String = "Test Item"
            let count: Int = 42
            let address: Address = Address()
            let tags: [String] = ["swift", "ui"]
        }

        var fields: [FieldItem] = []
        let encoder = FieldItemEncoder { field in
            fields.append(field)
        }
        try Nested().encode(to: encoder)
        
        // Test nested structure indentation
        #expect(fields.contains { $0.label == "field.id" && $0.value == "123" && $0.indent == 0 && $0.type == "String" })
        #expect(fields.contains { $0.label == "field.name" && $0.value == "Test Item" && $0.indent == 0 && $0.type == "String" })
        #expect(fields.contains { $0.label == "field.count" && $0.value == "42" && $0.indent == 0 && $0.type == "Int" })
        #expect(fields.contains { $0.label == "field.tags" && $0.value == "swift, ui" && $0.indent == 0 && $0.type == "Array<String>" })
        #expect(fields.contains { $0.label == "field.address" && $0.value == "" && $0.indent == 0 && $0.type == "Struct" })
        #expect(fields.contains { $0.label == "field.street" && $0.value == "123 Main St" && $0.indent == 1 && $0.type == "String" })
        #expect(fields.contains { $0.label == "field.city" && $0.value == "Springfield" && $0.indent == 1 && $0.type == "String" })
        #expect(fields.contains { $0.label == "field.country" && $0.value == "USA" && $0.indent == 1 && $0.type == "String" })
    }
    
    @Test func nestedStructures() throws {
        struct Nested: Encodable {
            struct Inner: Encodable {
                let value = "inner"
                struct Deeper: Encodable {
                    let value = "deeper"
                }
                let deeper = Deeper()
            }
            let inner = Inner()
        }
        
        var fields: [FieldItem] = []
        let encoder = FieldItemEncoder { field in
            fields.append(field)
        }
        try Nested().encode(to: encoder)
        
        // Test nested structure indentation
        #expect(fields.contains { $0.label == "field.inner" && $0.isNested && $0.indent == 0 && $0.type == "Struct" })
        #expect(fields.contains { $0.label == "field.value" && $0.value == "inner" && $0.indent == 1 && $0.type == "String" })
        #expect(fields.contains { $0.label == "field.deeper" && $0.isNested && $0.indent == 1 && $0.type == "Struct" })
        #expect(fields.contains { $0.label == "field.value" && $0.value == "deeper" && $0.indent == 2 && $0.type == "String" })
    }
    
    @Test func testModelTest() throws {
        struct TestModel: BlackbirdModel {
            static var indexes: [[BlackbirdColumnKeyPath]] = [
                [ \.$title ]
            ]
            
            static var cacheLimit: Int = 0

            @BlackbirdColumn var id: Int64
            @BlackbirdColumn var title: String
            @BlackbirdColumn var url: URL
            
            var nonColumn: String = ""
        }
        
        var fields = extractFields(from: TestModel(id: Int64(5), title: "Some Title", url: URL.platformCompatible(string: "https://tst.com")!), excludedFields: [], labelTemplate: "field")
        
        #expect(fields.contains { $0.label == "field.id" && $0.id == "5" })
    }
}
