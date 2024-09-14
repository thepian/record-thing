/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button to favorite a smoothie, can be placed in a toolbar.
*/

import SwiftUI

struct ProductFavoriteButton: View {
    @EnvironmentObject private var model: Model
    
    var isFavorite: Bool {
        guard let smoothieID = model.selectedProductID else { return false }
        return model.favoriteProductIDs.contains(smoothieID)
    }
    
    var body: some View {
        Button(action: toggleFavorite) {
            if isFavorite {
                Label {
                    Text("Remove from Favorites", comment: "Toolbar button/menu item to remove a smoothie from favorites")
                } icon: {
                    Image(systemName: "heart.fill")
                }
            } else {
                Label {
                    Text("Add to Favorites", comment: "Toolbar button/menu item to add a smoothie to favorites")
                } icon: {
                    Image(systemName: "heart")
                }

            }
        }
        .disabled(model.selectedProductID == nil)
    }
    
    func toggleFavorite() {
        guard let smoothieID = model.selectedProductID else { return }
        model.toggleFavorite(smoothieID: smoothieID)
    }
}

struct ProductFavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        ProductFavoriteButton()
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(Model())
    }
}
