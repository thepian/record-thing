//
//  ProductTypeRow.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ProductTypeRow: View {
    var product: ProductType
    
//    @EnvironmentObject private var model: Model

    var body: some View {
        HStack(alignment: .top) {
            let imageClipShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            product.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(imageClipShape)
                .overlay(imageClipShape.strokeBorder(.quaternary, lineWidth: 0.5))
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(product.fullName)
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
        ProductTypeRow(product: .Electronics)
        ProductTypeRow(product: .Pet)
    }
    .frame(width: 250, alignment: .leading)
    .padding(.horizontal)
    .previewLayout(.sizeThatFits)
    .environmentObject(Model())

}