/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom commands that you add to the application's Main Menu.
*/

import SwiftUI

struct ProductCommands: Commands {

    let model: Model

    var body: some Commands {
        CommandMenu(Text("Product", comment: "Menu title for smoothie-related actions")) {
            ProductFavoriteButton().environmentObject(model)
                .keyboardShortcut("+", modifiers: [.option, .command])
        }
    }
}
