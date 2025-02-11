//
//  DocumentTypeMenu.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct DocumentTypeMenu: View {
    // Async-loading, auto-updating array of matching instances

    var body: some View {
        DocumentTypeList()
            .navigationTitle(Text("Document Type", comment: "Title of the 'menu' app section showing the menu of available document types"))
    }
}

#Preview {
    @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
    @Previewable @StateObject var model = Model()

    NavigationView {
        DocumentTypeMenu()
    }
        .environment(\.blackbirdDatabase, database)
        .environmentObject(model)
}
