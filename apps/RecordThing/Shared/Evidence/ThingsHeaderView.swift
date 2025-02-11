//
//  ThingsHeaderView.swift
//  RecordThing
//
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

struct ThingsHeaderView: View {
    var thing: Things
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    var horizontallyConstrained: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        Group {
            if horizontallyConstrained {
                fullBleedContent
            } else {
                wideContent
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    var fullBleedContent: some View {
        VStack(spacing: 0) {
            thing.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(hidden: true)
            
            VStack(alignment: .leading) {
                Text(thing.description ?? "<description>")
                
                StructureFieldTableView(
                    "Details",
                    item: thing,
                    rightAlignValues: true,
                    fieldColumnName: "Property",
                    valueColumnName: "Value",
                    maxLines: 5
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background()
        }
    }
    
    var wideClipShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    var wideContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    #if os(macOS)
                    Text(thing.id)
                        .font(Font.largeTitle.bold())
                    #endif
                    Text(thing.description ?? "<description>")
                        .font(.title2)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background()
                
                thing.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 220, height: 250)
                    .clipped()
                    .accessibility(hidden: true)
            }
            .frame(height: 250)
            .clipShape(wideClipShape)
            .overlay {
                wideClipShape.strokeBorder(.quaternary, lineWidth: 0.5)
            }
            
            StructureFieldTableView(
                "Details",
                item: thing,
                rightAlignValues: true,
                fieldColumnName: "Property",
                valueColumnName: "Value",
                excluding: ["description"],
                maxLines: 5
            )
        }
        .padding()
    }
    }

/**
 @BlackbirdColumn var id: String  // KSUID
 @BlackbirdColumn var account_id: String
 
 // Product identifiers
 @BlackbirdColumn var upc: String?  // Universal Product Code
 @BlackbirdColumn var asin: String?  // Amazon Standard Identification Number
 @BlackbirdColumn var elid: String?  // Electronic Product Identifier
 
 // Product details
 @BlackbirdColumn var brand: String?
 @BlackbirdColumn var model: String?
 @BlackbirdColumn var color: String?
 @BlackbirdColumn var tags: String?  // JSON array
 @BlackbirdColumn var category: String?
 
 // Type references
 @BlackbirdColumn var product_type: Int?
 @BlackbirdColumn var document_type: Int?
 
 // Description fields
 @BlackbirdColumn var title: String?
 @BlackbirdColumn private var description: String?  // Backing field for description
 */


#Preview {
    NavigationStack {
        ThingsHeaderView(thing: .Electronics)
    }
}
