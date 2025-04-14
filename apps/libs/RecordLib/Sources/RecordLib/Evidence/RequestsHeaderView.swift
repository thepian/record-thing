//
//  DocumentTypeHeaderView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

public struct RequestsHeaderView: View {
    public var request: Requests
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    public init(request: Requests) {
        self.request = request
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
            request.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibility(hidden: true)
            
            VStack(alignment: .leading) {
                Text(request.title)
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
                Text(request.title)
                    .font(Font.largeTitle.bold())
                #endif
                Text(request.title)
                    .font(.title2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background()
            
            request.image
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
    RequestsHeaderView(request: .Electronics)
}
