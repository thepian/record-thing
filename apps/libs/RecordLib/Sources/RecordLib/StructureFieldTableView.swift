//
//  StructureFieldTableView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 11.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import Blackbird

#if os(macOS)
import AppKit
#endif

import Foundation

struct StructureFieldTableView: View {
    let title: String
    let rightAlignValues: Bool
    let fieldColumnName: String
    let valueColumnName: String
    let excludedFields: Set<String>
    let maxLines: Int?
    
    var fields: [FieldItem];
    
    init(
        _ title: String,
        fields: [FieldItem],
        labelTemplate: String? = nil,
        rightAlignValues: Bool = false,
        fieldColumnName: String = "Field",
        valueColumnName: String = "Value",
        excluding: [String] = [],
        maxLines: Int? = nil
    ) {
        self.title = title
        self.fields = fields
        self.rightAlignValues = rightAlignValues
        self.fieldColumnName = fieldColumnName
        self.valueColumnName = valueColumnName
        self.excludedFields = Set(excluding)
        self.maxLines = maxLines
    }
    
#if os(macOS)
    var table: some View {
        // macOS can use Table
        Table(fields, selection: .constant(nil)) {
            TableColumn(LocalizedStringKey(fieldColumnName)) { item in
                HStack {
                    if item.indent > 0 {
                        Spacer()
                            .frame(width: CGFloat(item.indent * 20))
                    }
                    Text(LocalizedStringKey(item.label))
                        .foregroundColor(item.isNested ? .secondary : .primary)
                        .fontWeight(item.isNested ? .bold : .regular)
                }
            }
            TableColumn(LocalizedStringKey(valueColumnName)) { item in
                if !item.isNested {
                    HStack {
                        if rightAlignValues {
                            Spacer()
                        }
                        Text(item.value)
                            .textSelection(.enabled)
                            .foregroundColor(.primary)
                    }
                }
            }
            .alignment(rightAlignValues ? .trailing : .leading)
        }
        .frame(height: min(CGFloat(fields.count) * 44, CGFloat(maxLines ?? fields.count) * 44)) // 44 is default row height, limit to maxLines rows
        .clipped()
//            .modify { view in
//                if let maxLines = maxLines {
//                    view.frame(height: min(CGFloat(fields.count) * 44, CGFloat(maxLines) * 44))
//                        .clipped()
//                } else {
//                    view
//                }
//            }
        .headerProminence(.increased)
    }
#endif
    
    var list: some View {
        // iOS uses List
        List(fields) { item in
            HStack {
                // Field name
                HStack {
                    if item.indent > 0 {
                        Spacer()
                            .frame(width: CGFloat(item.indent * 20))
                    }
                    Text(LocalizedStringKey(item.label))
                        .foregroundColor(item.isNested ? .secondary : .primary)
                        .fontWeight(item.isNested ? .bold : .regular)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Value
                if !item.isNested {
                    Text(item.value)
                        .textSelection(.enabled)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: rightAlignValues ? .trailing : .leading)
                }
            }
//            .listRowBackground(Color(.systemBackground))
        }
        .listStyle(.plain)
        .frame(height: min(CGFloat(fields.count) * 44, CGFloat(maxLines ?? fields.count) * 44)) // 44 is default row height, limit to maxLines rows
        .clipped()
//            .modify { view in
//                if let maxLines = maxLines {
//                    view.frame(height: min(CGFloat(fields.count) * 44, CGFloat(maxLines) * 44))
//                        .clipped()
//                } else {
//                    view
//                }
//            }
        .headerProminence(.increased)

    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(title))
                .font(.headline)
                .padding(.bottom, 8)
            
            FieldsTable(rightAlignValues: rightAlignValues, fieldColumnName: fieldColumnName, valueColumnName: valueColumnName, maxLines: maxLines, fields: fields)
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemBackground))
        #endif
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// Updated Previews
/*
struct StructureFieldTableView_Previews: PreviewProvider {
    struct NestedStruct {
        struct Address {
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

    static var sampleFields = extractFields(from: NestedStruct(), excludedFields: [], labelTemplate: "{field}")
    static var fieldsWithTemplate = extractFields(from: NestedStruct(), excludedFields: [], labelTemplate: "field.{field}")

    struct LeftAlignedExamples: View {

        var body: some View {
            VStack(spacing: 20) {
                // Default usage
                StructureFieldTableView("Sample Data", fields: sampleFields)
                
                // With label template
                StructureFieldTableView(
                    "Sample Data with Template",
                    fields: fieldsWithTemplate,
                    fieldColumnName: "Property",
                    valueColumnName: "Data"
                )
            }
            .padding()
        }
    }
    
    struct RightAlignedExample: View {
        var body: some View {
            StructureFieldTableView(
                "Right-aligned Values",
                fields: sampleFields,
                rightAlignValues: true,
                fieldColumnName: "Metric",
                valueColumnName: "Amount"
            )
            .padding()
        }
    }
    
    // Sample JSON structure
    static let jsonString = """
    {
        "metrics": {
            "totalRequests": 1234,
            "averageLatency": 42.5,
            "errorRate": 0.01
        },
        "status": {
            "isHealthy": true,
            "lastCheck": "2024-03-14T15:09:26Z",
            "nodes": ["us-east", "eu-west"]
        }
    }
    """
    
    struct JsonExample: View {
        let jsonData: Any
        var fields: [FieldItem]
        
        init() {
            let data = Data(jsonString.utf8)
            do {
                // Use options to preserve number types
                self.jsonData = try JSONSerialization.jsonObject(
                    with: data,
                    options: [.fragmentsAllowed]
                )
            } catch {
                self.jsonData = ["error": "Failed to parse JSON"]
            }
            self.fields = extractFields(from: self.jsonData, excludedFields: ["isHealthy"], labelTemplate: "{field}")
        }
        
        var body: some View {
            StructureFieldTableView(
                "API Metrics",
                fields: fields,
                rightAlignValues: true,
                fieldColumnName: "Metric",
                valueColumnName: "Value"
            )
            .padding()
        }
    }
    
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
    
    static var testModelFields = extractFields(from: TestModel(id: Int64(5), title: "Some Title", url: URL.platformCompatible(string: "https://tst.com")!), excludedFields: [], labelTemplate: "field")

    struct BlackbirdExample: View {
        var body: some View {
            StructureFieldTableView(
                "Test Model from DB",
                fields: testModelFields,
                rightAlignValues: true,
                fieldColumnName: "Metric",
                valueColumnName: "Amount"
            )
            .padding()
        }
    }

    static var previews: some View {
        Group {
            LeftAlignedExamples()
                .previewDisplayName("Left Aligned Examples")
            
            RightAlignedExample()
                .previewDisplayName("Right Aligned Example")
            
            JsonExample()
                .previewDisplayName("JSON Data Example")
            
            BlackbirdExample()
                .previewDisplayName("Blackbird Example")
        }
    }
    
}
*/
