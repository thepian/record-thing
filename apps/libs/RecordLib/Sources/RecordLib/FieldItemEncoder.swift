//
//  FieldItemEncoder.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 23.02.2025.
//

import Foundation

// Helper function to determine if an array contains complex types
func isComplexArray(_ value: Any) -> Bool {
    guard let array = value as? [Any] else { return false }
    return array.contains { item in
        item is [String: Any] ||
        item is [Any] ||
        Mirror(reflecting: item).children.isEmpty == false
    }
}

func getFieldValue(value: Any?) -> String {
    switch value {
    case let value as String:
        return value
    case let value as Int:
        return String(value)
    case let value as Float:
        return String(value)
    case let value as Double:
        return String(value)
    case let value as Bool:
        return value ? "true" : "false"
    case let value as Date:
        return String(describing: value)
    case let v as Array<Any>:
        return v.map { getFieldValue(value: $0) }.joined(separator: ", ")
//        case nil:
//            return "nil"
//    case let value as Optional<Any>:
//        // Handle optionals
//        if let unwrapped = value {
//            return String(describing: unwrapped)
//        }
//        return "nil"
    default:
        return String(describing: value)
    }
}



struct FieldItem: Identifiable {
    let id: String
    let label: String
    let value: String
    let type: String
    let indent: Int
    let isOptional: Bool
    let isNested: Bool

    /*
    init(label: String, value: Any?, indent: Int = 0, labelTemplate: String? = nil, isOptional: Bool = false) {
        let label = labelTemplate?.replacingOccurrences(of: "{field}", with: label) ?? label
        
        // For direct struct properties, skip array complexity check
        if let array = value as? [Any], !array.isEmpty {
            if !array.contains(where: {
                $0 is [String: Any] ||
                $0 is [Any] ||
                Mirror(reflecting: $0).children.isEmpty == false
            }) {
                self.init(label: label, value: array.map { getFieldValue(value: $0) }.joined(separator: ", "), type: "<TODO>", indent: indent, labelTemplate: labelTemplate,
                          isNested: false, // Simple arrays are not nested
                          isOptional: isOptional
                )
            } else {
                self.init(label: label, value: getFieldValue(value: value), type: "<TODO>", indent: indent, labelTemplate: labelTemplate, isNested: true, isOptional: isOptional)
            }
        } else {
            self.init(label: label, value: getFieldValue(value: value), type: "<TODO>", indent: indent, labelTemplate: labelTemplate, isNested: Mirror(reflecting: value as Any).children.isEmpty == false, isOptional: isOptional)
        }
    }
     */

    init(label: String, value: Any, type: String, indent: Int = 0, labelTemplate: String? = nil, isOptional: Bool = false, isNested: Bool? = nil) {
        self.id = UUID().uuidString
        self.label = labelTemplate?.replacingOccurrences(of: "{field}", with: label) ?? label
        self.value = getFieldValue(value: value)
        self.type = type
        self.indent = indent
        self.isOptional = isOptional
        self.isNested = isNested ?? Mirror(reflecting: value).children.isEmpty == false
    }
}

// https://medium.com/codex/how-to-create-your-own-encoder-decoder-using-swift-cfe6a01ef3e7

struct FieldItemEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    var baseIndent: Int = 0
    var labelTemplate: String = "field.{field}"

    let onField: (FieldItem) -> Void
    
    init(onField: @escaping (FieldItem) -> Void) {
        self.onField = onField
    }
    
    // Container creators
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        SingleValueContainer(encoder: self)
    }
    
    // Helper to add field items
    mutating func addField(label: String, value: Any?, type: String, isOptional: Bool = false) {
        let fieldItem = FieldItem(
            label: label,
            value: value as Any,
            type: type,
            indent: baseIndent + codingPath.count,
            labelTemplate: labelTemplate,
            isOptional: isOptional
        )
        onField(fieldItem)
    }
    
    mutating func addFieldForValue<T>(_ value: T, key: CodingKey, isOptional: Bool = false) throws where T: Encodable {

        // Handle basic types
        switch value {
        case let v as Int:
            addField(label: key.stringValue, value: v, type: "Int", isOptional: isOptional)
        case let v as String:
            addField(label: key.stringValue, value: v, type: "String", isOptional: isOptional)
        case let v as Double:
            addField(label: key.stringValue, value: v, type: "Double", isOptional: isOptional)
        case let v as Float:
            addField(label: key.stringValue, value: v, type: "Float", isOptional: isOptional)
        case let v as Bool:
            addField(label: key.stringValue, value: v, type: "Bool", isOptional: isOptional)
        case let v as Date:
            addField(label: key.stringValue, value: v, type: "Date", isOptional: isOptional)
        case let v as URL:
            addField(label: key.stringValue, value: v, type: "URL", isOptional: isOptional)
        case let v as Array<Any>:
            if isComplexArray(v) {
                addField(label: key.stringValue, value: "", type: "Array", isOptional: isOptional)
                codingPath.append(key)
                try value.encode(to: self)
                codingPath.removeLast()
            } else {
                addField(label: key.stringValue, value: v.map { getFieldValue(value: $0) }.joined(separator: ", "), type: String(describing: T.self))
            }
        case let v as any RawRepresentable:
            // Handle enums
            addField(label: key.stringValue, value: v.rawValue, type: String(describing: T.self))
        default:
            addField(label: key.stringValue, value: "", type: "Struct", isOptional: isOptional)
            // Handle other Encodable types
            codingPath.append(key)
            try value.encode(to: self)
            codingPath.removeLast()
        }

    }
    
    // Container for Structs
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: FieldItemEncoder
        var codingPath: [CodingKey] { encoder.codingPath }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            encoder.codingPath.append(key)
            let container = KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder))
            encoder.codingPath.removeLast()
            return container
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            encoder.codingPath.append(key)
            let container = UnkeyedContainer(encoder: encoder)
            encoder.codingPath.removeLast()
            return container
        }
        
        mutating func superEncoder() -> Encoder {
            encoder
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            encoder.codingPath.append(key)
            return encoder
        }
        
        mutating func encodeNil(forKey key: Key) throws {
            encoder.addField(label: key.stringValue, value: "nil", type: "nil", isOptional: true)
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            // Handle optionals first (hmm, seems nil gets skipped)
            let mirror = Mirror(reflecting: value)
            let isOptional = mirror.displayStyle == .optional
            if isOptional {
                if case Optional<Any>.none = value as Any {
                    try encodeNil(forKey: key)
                    return
                }
                // If we have a value, it will be handled by the cases below
            }
            
            try encoder.addFieldForValue(getBlackbirdColumnValue(value, mirror: mirror) ?? value, key: key, isOptional: isOptional)
        }
    }
    
    // Container for Lists/Arrays
    private struct UnkeyedContainer: UnkeyedEncodingContainer {
        var encoder: FieldItemEncoder
        var codingPath: [CodingKey] { encoder.codingPath }
        var count: Int = 0
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            let container = KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder))
            count += 1
            return container
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let container = UnkeyedContainer(encoder: encoder)
            count += 1
            return container
        }
        
        mutating func superEncoder() -> Encoder {
            encoder
        }
        
        mutating func encodeNil() throws {
            encoder.addField(label: "[\(count)]", value: "nil", type: "nil", isOptional: true)
            count += 1
        }
        
        mutating func encode<T>(_ value: T) throws where T: Encodable {
            if let enumValue = value as? any RawRepresentable {
                encoder.addField(label: "[\(count)]", value: enumValue.rawValue, type: String(describing: T.self))
            } else {
                try value.encode(to: encoder)
            }
            count += 1
        }
    }
    
    private struct SingleValueContainer: SingleValueEncodingContainer {
        var encoder: FieldItemEncoder
        var codingPath: [CodingKey] { encoder.codingPath }
        
        mutating func encodeNil() throws {
            let label = codingPath.last?.stringValue ?? "value"
            encoder.addField(label: label, value: "nil", type: "nil", isOptional: true)
        }
        
        mutating func encode<T>(_ value: T) throws where T: Encodable {
            let label = codingPath.last?.stringValue ?? "value"
            
            // Handle basic types first
            switch value {
            case let v as Int:
                encoder.addField(label: label, value: v, type: "Int")
            case let v as String:
                encoder.addField(label: label, value: v, type: "String")
            case let v as String?:
                encoder.addField(label: label, value: v, type: "String?") // TODO optional something
            case let v as Double:
                encoder.addField(label: label, value: v, type: "Double")
            case let v as Float:
                encoder.addField(label: label, value: v, type: "Float")
            case let v as Bool:
                encoder.addField(label: label, value: v, type: "Bool")
            case let v as Date:
                encoder.addField(label: label, value: v, type: "Date")
            case let v as URL:
                encoder.addField(label: label, value: v, type: "URL")
            case let v as any RawRepresentable:
                // Handle enums
                encoder.addField(label: label, value: v.rawValue, type: String(describing: T.self))
            default:
                // Handle other Encodable types
                try value.encode(to: encoder)
            }
        }
    }
}

func extractFields(from value: Any?, excludedFields: Set<String>, labelTemplate: String?, indent: Int = 0) -> [FieldItem] {
    var fields: [FieldItem] = []
    var encoder = FieldItemEncoder { field in
        fields.append(field)
    }
    encoder.baseIndent = indent
    if let labelTemplate = labelTemplate {
        encoder.labelTemplate = labelTemplate
    }

    if let value = value {
        // Handle Encodable values
        if let encodable = value as? Encodable {
            do {
                try encodable.encode(to: encoder)
            } catch let error {
                print("Error encoding \(error)")
            }
        }
        // Handle top-level arrays
        else if let array = value as? [Any] {
            if isComplexArray(array) {
                for (index, entry) in array.enumerated() {
                    encoder.addField(label: "[\(index)]", value: entry, type: String(describing: type(of: entry)))
                    if value is [String: Any] || value is [Any] {
                        fields.append(contentsOf: extractFields(from: value, excludedFields: excludedFields, labelTemplate: labelTemplate, indent: indent + 1))
                    }
                }
            }
        }
        // Handle top-level dictionaries
        else if let dict = value as? [String: Any] {
            for (key, value) in dict {
                // Skip excluded fields and internal fields
                guard !excludedFields.contains(key) else { continue }
                encoder.addField(label: key, value: value, type: String(describing: type(of: value)))
                if value is [String: Any] || isComplexArray(value) {
                    fields.append(contentsOf: extractFields(from: value, excludedFields: excludedFields, labelTemplate: labelTemplate, indent: indent + 1))
                }
            }
            return fields
        } else {
            // Handle struct/class using Mirror
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .struct || mirror.displayStyle == .class {
                for child in mirror.children {
                    // Handle regular properties
                    guard let label = child.label else { continue }
                    guard !excludedFields.contains(label) else { continue }
                    
                    if isComplexArray(child.value) {
                        encoder.addField(label: label, value: "", type: String(describing: type(of: value)))

                        if Mirror(reflecting: child.value).children.isEmpty == false && isComplexArray(child.value) && indent < 3 {
                            fields.append(contentsOf: extractFields(from: child.value, excludedFields: excludedFields, labelTemplate: labelTemplate, indent: indent + 1))
                        }
                    } else {
                        encoder.addField(label: label, value: child.value, type: String(describing: type(of: value)))
                    }
                }
            }
        }

    }
            
    return fields
}
    
