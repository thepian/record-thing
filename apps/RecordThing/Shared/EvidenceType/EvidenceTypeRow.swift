//
//  EvidenceTypeRow.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import RecordLib

struct EvidenceTypeRow: View {
    var type: EvidenceType
    
//    @EnvironmentObject private var model: Model

    var body: some View {
        HStack(alignment: .top) {
            let imageClipShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            type.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(imageClipShape)
                .overlay(imageClipShape.strokeBorder(.quaternary, lineWidth: 0.5))
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(type.name)
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

#Preview(traits: .sizeThatFitsLayout) {
    Group {
        EvidenceTypeRow(type: .Electronics)
        EvidenceTypeRow(type: .Pet)
    }
    .frame(width: 250, alignment: .leading)
    .padding(.horizontal)
    .environmentObject(Model(loadedLangConst: "en"))

}
