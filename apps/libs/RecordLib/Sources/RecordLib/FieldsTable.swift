//
//  FieldsTable.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 24.02.2025.
//

import SwiftUI
import Blackbird

#if os(macOS)
import AppKit
#endif

import Foundation

struct FieldsTable: View {
    let rightAlignValues: Bool
    let fieldColumnName: String
    let valueColumnName: String
    let maxLines: Int?

    var fields: [FieldItem]
    
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
        .id("fieldsTable")
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
    
#if os(iOS)
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
#endif
    
    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
            #if os(macOS)
            table
            #else
            list
            #endif
//        }
//        .padding()
//        #if os(iOS)
//        .background(Color(.systemBackground))
//        #endif
//        .cornerRadius(8)
//        .shadow(radius: 2)
    }

}

struct FieldsTable_Previews: PreviewProvider {
    
    static let basicFields: [FieldItem] = [
        FieldItem(label: "Name", value: "John Doe", type: "String"),
        FieldItem(label: "Age", value: 42, type: "Int"),
        FieldItem(label: "Active", value: true, type: "Bool"),
        FieldItem(label: "Created", value: Date(), type: "Date")
    ]
    
    static let nestedFields: [FieldItem] = [
        FieldItem(label: "User", value: "", type: "Struct", isNested: true),
        FieldItem(label: "name", value: "John Doe", type: "String", indent: 1),
        FieldItem(label: "email", value: "john@example.com", type: "String", indent: 1),
        FieldItem(label: "Address", value: "", type: "Struct", indent: 1, isNested: true),
        FieldItem(label: "street", value: "123 Main St", type: "String", indent: 2),
        FieldItem(label: "city", value: "Springfield", type: "String", indent: 2)
    ]
    
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
    
    struct BasicFields: View {
        var body: some View {
            VStack {
                Text("Basic Fields")
                FieldsTable(
                    rightAlignValues: false,
                    fieldColumnName: "Descriptions",
                    valueColumnName: "Values",
                    maxLines: 10,
                    fields: basicFields
                )
            }.padding()
        }
    }

    struct NestedFields: View {
        var body: some View {
            VStack {
                Text("Nested Fields")
                FieldsTable(
                    rightAlignValues: true,
                    fieldColumnName: "Property",
                    valueColumnName: "Value",
                    maxLines: 10,
                    fields: nestedFields
                )
            }.padding()
        }
    }
    
    struct TestModelView: View {
        var body: some View {
            VStack {
                Text("Test Model")
                FieldsTable(rightAlignValues: true, fieldColumnName: "Property", valueColumnName: "Value", maxLines: 10, fields: testModelFields)
            }.padding()
        }
    }
    
    static var previews: some View {
        Group {
            BasicFields()
                .previewDisplayName("Basic Fields")
            NestedFields()
                .previewDisplayName("Nested Fields")
//            TestModelView()
//                .previewDisplayName("Test Model")
        }
    }
}
