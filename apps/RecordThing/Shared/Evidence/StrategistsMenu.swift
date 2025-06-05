//
//  StrategistsMenu.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct StrategistsMenu: View {
    // Async-loading, auto-updating array of matching instances

    var body: some View {
        StrategistsList()
            .navigationTitle(Text(LocalizedStringKey(stringLiteral: "nav.strategists"), comment: "Title of the 'menu' app section showing the menu of available strategists"))
    }
}

#Preview {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        StrategistsMenu()
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
