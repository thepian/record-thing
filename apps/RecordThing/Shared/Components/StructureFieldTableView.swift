//
//  StructureFieldTableView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 11.02.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

// Custom modifier for older SwiftUI versions that don't have .alternatingRowBackgrounds()
struct AlternatingRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set the alternating background colors
                UITableView.appearance().backgroundColor = .systemBackground
                UITableView.appearance().separatorColor = .separator
                
                // Set alternating row colors
                UITableView.appearance().backgroundView = nil
                UITableView.appearance().backgroundColor = nil
                
                let alternatingColors = [
                    UIColor.systemBackground.cgColor,
                    UIColor.systemGray6.cgColor
                ]
                
                let background = CALayer()
                background.frame = CGRect(x: 0, y: 0, width: 1, height: 44) // 44 is default row height
                
                let alternatingColorLayer = CALayer()
                alternatingColorLayer.frame = background.bounds
                
//                let gradient = CAGradient(layer: alternatingColorLayer)
//                gradient.colors = alternatingColors
//                gradient.locations = [0, 0.5, 0.5, 1]
//                gradient.startPoint = CGPoint(x: 0, y: 0)
//                gradient.endPoint = CGPoint(x: 0, y: 1)
//                
//                alternatingColorLayer.addSublayer(gradient)
                background.addSublayer(alternatingColorLayer)
                
                UITableView.appearance().backgroundView = UIView()
                UITableView.appearance().backgroundView?.layer.addSublayer(background)
            }
    }
}

/*

// Extract fields with specific types
var valueFields: [String: Any] {
    Mirror(reflecting: item).children.compactMap { child in
        guard let label = child.label else { return nil }
        
        // Filter for specific types
        switch child.value {
        case let value as String:
            return (label, value)
        case let value as Int:
            return (label, value)
        case let value as Bool:
            return (label, value)
        case let value as Date:
            return (label, value)
        case let value as Optional<Any>:
            // Handle optionals
            if let unwrapped = value {
                return (label, unwrapped)
            }
            return nil
        default:
            return nil
        }
    }.reduce(into: [:]) { dict, tuple in
        dict[tuple.0] = tuple.1
    }
}

// Or to get specific fields by name
var specificFields: [String: Any] {
    Mirror(reflecting: item).children.compactMap { child in
        guard
            let label = child.label,
            ["id", "name", "url"].contains(label)  // Only these fields
        else { return nil }
        
        return (label, child.value)
    }.reduce(into: [:]) { dict, tuple in
        dict[tuple.0] = tuple.1
    }
}

// Or to get non-nil values only
var nonNilFields: [String: Any] {
    Mirror(reflecting: item).children.compactMap { child in
        guard
            let label = child.label,
            !(child.value is Optional<Any>) ||
            (child.value as? Optional<Any>).flatMap({ $0 }) != nil
        else { return nil }
        
        return (label, child.value)
    }.reduce(into: [:]) { dict, tuple in
        dict[tuple.0] = tuple.1
    }
}

*/


struct FieldItem: Identifiable {
    let id: String
    let label: String
    let value: String
    let indent: Int
    let isNested: Bool
    
    init(label: String, value: Any, indent: Int = 0, labelTemplate: String? = nil) {
        self.id = UUID().uuidString
        self.label = labelTemplate?.replacingOccurrences(of: "{field}", with: label) ?? label
        self.value = String(describing: value)
        self.indent = indent
        self.isNested = Mirror(reflecting: value).children.isEmpty == false
    }
}

struct StructureFieldTableView<T>: View {
    let item: T
    let title: String
    let labelTemplate: String?
    let rightAlignValues: Bool
    let fieldColumnName: String
    let valueColumnName: String
    
    init(
        _ title: String,
        item: T,
        labelTemplate: String? = nil,
        rightAlignValues: Bool = false,
        fieldColumnName: String = "Field",
        valueColumnName: String = "Value"
    ) {
        self.title = title
        self.item = item
        self.labelTemplate = labelTemplate
        self.rightAlignValues = rightAlignValues
        self.fieldColumnName = fieldColumnName
        self.valueColumnName = valueColumnName
    }
    
    func extractFields(from value: Any, indent: Int = 0) -> [FieldItem] {
        let mirror = Mirror(reflecting: value)
        var fields: [FieldItem] = []
        
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            let fieldItem = FieldItem(
                label: label,
                value: child.value,
                indent: indent,
                labelTemplate: labelTemplate
            )
            fields.append(fieldItem)
            
            if fieldItem.isNested {
                fields.append(contentsOf: extractFields(from: child.value, indent: indent + 1))
            }
        }
        
        return fields
    }
    
    var fields: [FieldItem] {
        extractFields(from: item)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(title))
                .font(.headline)
                .padding(.bottom, 8)
            
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
            .headerProminence(.increased)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

// Updated Previews
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
    
    struct LeftAlignedExamples: View {
        var body: some View {
            VStack(spacing: 20) {
                // Default usage
                StructureFieldTableView("Sample Data", item: NestedStruct())
                
                // With label template
                StructureFieldTableView(
                    "Sample Data with Template",
                    item: NestedStruct(),
                    labelTemplate: "field.{field}",
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
                item: NestedStruct(),
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
        }
    }
}
