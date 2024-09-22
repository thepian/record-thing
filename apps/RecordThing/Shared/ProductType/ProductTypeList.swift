//
//  ProductTypeList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import Blackbird

struct ProductTypeList: View {
    
    // Async-loading, auto-updating array of matching instances
    @BlackbirdLiveModels({ try await ProductType.read(from: $0, orderBy: .ascending(\.$name)) }) var types

    var body: some View {
        if types.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(types.results) { productType in
                        NavigationLink(tag: productType.name, selection: $model.selectedProductID) {
                            ProductTypeView(product: productType)
                        } label: {
                            ProductTypeRow(product: productType)
                        }
                        .onChange(of: model.selectedProductID) { newValue in
                            // Need to make sure the Product exists.
    //                        guard let smoothieID = newValue, let product = ProducType(for: smoothieID) else { return }
    //                        proxy.scrollTo(product.id)
    //                        model.selectedProductID = product.id
                        }
                        .swipeActions {
                            Button {
                                withAnimation {
//                                    model.toggleFavorite(smoothieID: product.id)
                                }
                            } label: {
                                Label {
                                    Text("Favorite", comment: "Swipe action button in product list")
                                } icon: {
                                    Image(systemName: "heart")
                                }
                            }
                            .tint(.accentColor)
                        }


                    }
                }
                .accessibilityRotor("Products", entries: products, entryLabel: \.fullName)
                .accessibilityRotor("Favorite Products", entries: products.filter { model.isFavorite(product: $0) }, entryLabel: \.fullName)
                .searchable(text: $model.searchString) {
                    ForEach(model.searchSuggestions) { suggestion in
                        Text(suggestion.name).searchCompletion(suggestion.name)
                    }
                }

            }
        } else {
            Group {
                ProgressView()
                Text("Loading")
            }
        }
    }
    
    
    var products: [ProductType]

    @EnvironmentObject private var model: Model
    
    var listedProducts: [ProductType] {
        products
//            .filter { $0.matches(model.searchString) }
            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
    }
}

#Preview {
    ProductTypeList(products: ProductType.all())
}
