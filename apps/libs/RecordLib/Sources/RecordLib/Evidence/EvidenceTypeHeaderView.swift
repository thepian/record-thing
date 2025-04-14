//
//  EvidenceTypeHeaderView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

public struct EvidenceTypeHeaderView: View {
    public var type: EvidenceType
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    public init(type: EvidenceType) {
        self.type = type
    }
    
    public var horizontallyConstrained: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    public var body: some View {
        Group {
            if horizontallyConstrained {
                fullBleedContent
            } else {
                wideContent
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    public var fullBleedContent: some View {
        VStack(spacing: 0) {
            type.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(hidden: true)
            
            VStack(alignment: .leading) {
                Text(type.description)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background()
        }
    }
    
    public var wideClipShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    public var wideContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                #if os(macOS)
                Text(type.description)
                    .font(Font.largeTitle.bold())
                #endif
                Text(type.description)
                    .font(.title2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background()
            
            type.image
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
    EvidenceTypeHeaderView(type: .Electronics)
}
