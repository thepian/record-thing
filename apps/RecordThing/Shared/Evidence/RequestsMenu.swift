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
            .navigationTitle(Text("nav.requests", comment: "Title of the 'menu' app section showing the menu of available things"))
    }
}

#Preview {
    @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
    @Previewable @StateObject var model = Model()

    NavigationView {
        RequestsMenu()
    }
    .environment(\.blackbirdDatabase, database)
    .environmentObject(model)
}
