//
//  ProductTypeList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct ProductTypeList: View {
    @BlackbirdLiveModels({ try await ProductType.read(from: $0, orderBy: .ascending(\.$name)) }) var types
    @EnvironmentObject private var model: Model

    var body: some View {
//        if types.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(types.results) { productType in
                        NavigationLink(destination: {
                            ProductTypeView(product: productType)
                        }, label: {
                            ProductTypeRow(product: productType)
                        })
//                       NavigationLink(tag: productType.name, selection: $model.selectedTypeID) { }
                        .onChange(of: model.selectedTypeID) { newValue in
                            // Need to make sure the Product exists.
                //                        guard let typeID = newValue, let product = ProductType(for: typeID) else { return }
                //                        proxy.scrollTo(product.id)
                //                        model.selectedTypeID = product.id
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
//                .accessibilityRotor("Products", entries: types, entryLabel: \.fullName)
//                .accessibilityRotor("Favorite Products", entries: types.filter { model.isFavorite(product: $0) }, entryLabel: \.fullName)
//                    .searchable(text: $model.searchString) {
//                        ForEach(model.searchSuggestions) { suggestion in
//                            Text(suggestion.name).searchCompletion(suggestion.name)
//                        }
//                    }
            }
//        } else {
//            Group {
//                ProgressView()
//                Text("Loading")
//            }
//        }
    }
    
//    var products: [ProductType]

//    @EnvironmentObject private var model: Model
    
//    var listedProducts: [ProductType] {
//        types.results
//            .filter { $0.matches(model.searchString) }
//            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
//    }
}

#Preview {
    ProductTypeList()
}
