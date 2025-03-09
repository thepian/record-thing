//
//  EvidenceTypeMenu.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct EvidenceTypeMenu: View {
    // Async-loading, auto-updating array of matching instances

    @EnvironmentObject private var model: Model

    var body: some View {
        EvidenceTypeList()
            .navigationTitle(Text("nav.types", comment: "Title of the 'menu' app section showing the menu of available product types"))
    }
}

//#Preview {
//    EvidenceTypeMenu().environmentObject(Model(loadedLangConst: "en"))
//}
#Preview {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        EvidenceTypeMenu()
//            .navigationTitle(LocalizedStringKey(stringLiteral: "nav.types"))
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
