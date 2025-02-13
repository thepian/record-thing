//
//  ThingsMenu.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct ThingsMenu: View {
    // Async-loading, auto-updating array of matching instances

    var body: some View {
        ThingsList()
            .navigationTitle(Text(LocalizedStringKey(stringLiteral: "nav.things"), comment: "Title of the 'menu' app section showing the menu of available things"))
    }
}

#Preview {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        ThingsMenu()
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
