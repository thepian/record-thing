//
//  DocumentTypeMenu.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import Blackbird

struct DocumentTypeMenu: View {
    // Async-loading, auto-updating array of matching instances
    @BlackbirdLiveModels({ try await DocumentType.read(from: $0, orderBy: .ascending(\.$name)) }) var types

    var body: some View {
        if types.didLoad {
            DocumentTypeList(results: types.$results)
                .navigationTitle(Text("Document Type", comment: "Title of the 'menu' app section showing the menu of available document types"))
        } else {
            Group {
                ProgressView()
                Text("Loading")
            }
        }
    }
}

#Preview {
    DocumentTypeMenu().environmentObject(Model())
}
