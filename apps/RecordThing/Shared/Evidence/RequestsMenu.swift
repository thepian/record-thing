//
//  ThingsMenu.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct RequestsMenu: View {
    // Async-loading, auto-updating array of matching instances

    var body: some View {
        RequestsList()
            .navigationTitle(Text(LocalizedStringKey(stringLiteral: "nav.requests"), comment: "Title of the 'menu' app section showing the menu of available things"))
    }
}

#Preview {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        RequestsMenu()
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
