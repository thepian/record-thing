//
//  DocumentTypeHeaderView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

struct DocumentTypeHeaderView: View {
    var document: DocumentType
    
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
            document.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(hidden: true)
            
            VStack(alignment: .leading) {
                Text(document.description)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background()
        }
    }
    
    var wideClipShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    var wideContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                #if os(macOS)
                Text(document.fullName)
                    .font(Font.largeTitle.bold())
                #endif
                Text(document.description)
                    .font(.title2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background()
            
            document.image
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
        .padding()
    }
}

#Preview {
    DocumentTypeHeaderView(document: .Card)
}
