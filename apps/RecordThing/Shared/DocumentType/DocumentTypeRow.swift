//
//  DocumentTypeRow.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct DocumentTypeRow: View {
    var document: DocumentType
    
//    @EnvironmentObject private var model: Model

    var body: some View {
        HStack(alignment: .top) {
            let imageClipShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            document.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(imageClipShape)
                .overlay(imageClipShape.strokeBorder(.quaternary, lineWidth: 0.5))
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(document.fullName)
                    .font(.headline)
            }
            
            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
    
    
    var cornerRadius: Double {
        #if os(iOS)
        return 10
        #else
        return 4
        #endif
    }
}

#Preview {
    Group {
        DocumentTypeRow(document: .Card)
        DocumentTypeRow(document: .Receipt)
    }
    .frame(width: 250, alignment: .leading)
    .padding(.horizontal)
    .previewLayout(.sizeThatFits)
    .environmentObject(Model())

}
