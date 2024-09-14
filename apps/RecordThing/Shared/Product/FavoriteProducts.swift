/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The favorites tab or content list that includes smoothies marked as favorites.
*/

import SwiftUI

struct FavoriteProducts: View {
    @EnvironmentObject private var model: Model

    var favoriteProducts: [ProductDef] {
        model.favoriteProductIDs.map { ProductDef(for: $0)! }
    }
    
    var body: some View {
        ProductList(products: favoriteProducts)
            .overlay {
                if model.favoriteProductIDs.isEmpty {
                    Text("Add some smoothies to your favorites!",
                         comment: "Placeholder text shown in list of smoothies when no favorite smoothies have been added yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background()
                        .ignoresSafeArea()
                }
            }
            .navigationTitle(Text("Favorites", comment: "Title of the 'favorites' app section showing the list of favorite smoothies"))
            .environmentObject(model)
    }
}

struct FavoriteProducts_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteProducts()
            .environmentObject(Model())
    }
}
