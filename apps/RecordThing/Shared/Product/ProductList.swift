/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A reusable view that can display a list of arbritary smoothies.
*/

import SwiftUI

struct ProductList: View {
    var products: [ProductDef]

    @EnvironmentObject private var model: Model
    
    var listedProducts: [ProductDef] {
        products
            .filter { $0.matches(model.searchString) }
            .sorted(by: { $0.title.localizedCompare($1.title) == .orderedAscending })
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(listedProducts) { product in
                    NavigationLink(tag: product.id, selection: $model.selectedProductID) {
                        ProductView(product: product)
                    } label: {
                        ProductRow(product: product)
                    }
                    .onChange(of: model.selectedProductID) { newValue in
                        // Need to make sure the Product exists.
                        guard let smoothieID = newValue, let product = ProductDef(for: smoothieID) else { return }
                        proxy.scrollTo(product.id)
                        model.selectedProductID = product.id
                    }
                    .swipeActions {
                        Button {
                            withAnimation {
                                model.toggleFavorite(smoothieID: product.id)
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
            .accessibilityRotor("Products", entries: products, entryLabel: \.title)
            .accessibilityRotor("Favorite Products", entries: products.filter { model.isFavorite(product: $0) }, entryLabel: \.title)
            .searchable(text: $model.searchString) {
                ForEach(model.searchSuggestions) { suggestion in
                    Text(suggestion.name).searchCompletion(suggestion.name)
                }
            }
        }
    }
}

struct ProductList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([ColorScheme.light, .dark], id: \.self) { scheme in
            NavigationView {
                ProductList(products: ProductDef.all())
                    .navigationTitle(Text("Products", comment: "Navigation title for the full list of smoothies"))
                    .environmentObject(Model())
            }
            .preferredColorScheme(scheme)
        }
    }
}
