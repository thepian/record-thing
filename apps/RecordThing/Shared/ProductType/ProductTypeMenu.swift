//
//  ProductType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ProductTypeMenu: View {
    @EnvironmentObject private var model: Model

    var body: some View {
        ProductTypeList(products: ProductType.all())
            .navigationTitle(Text("Product Type", comment: "Title of the 'menu' app section showing the menu of available product types"))
    }
}

#Preview {
    ProductTypeMenu().environmentObject(Model())
}
