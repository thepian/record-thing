/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The menu tab or content list that includes all smoothies.
*/

import SwiftUI

struct ProductMenu: View {
    
    var body: some View {
        ProductList(products: ProductDef.all())
            .navigationTitle(Text("Menu", comment: "Title of the 'menu' app section showing the menu of available smoothies"))
    }
    
}

struct ProductMenu_Previews: PreviewProvider {
    static var previews: some View {
        ProductMenu()
            .environmentObject(Model())
    }
}
