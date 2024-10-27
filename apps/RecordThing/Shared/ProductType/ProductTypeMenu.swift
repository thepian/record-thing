//
//  ProductType.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import Blackbird

struct ProductTypeMenu: View {
    // Async-loading, auto-updating array of matching instances
    @BlackbirdLiveModels({ try await ProductType.read(from: $0, orderBy: .ascending(\.$name)) }) var types

    @EnvironmentObject private var model: Model

    var body: some View {
        ProductTypeList(results: types.$results)
            .navigationTitle(Text("Product Type", comment: "Title of the 'menu' app section showing the menu of available product types"))
    }
}

#Preview {
    ProductTypeMenu().environmentObject(Model())
}
