//
//  ThingsList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird
import RecordLib

struct ThingsList: View {
    
    @BlackbirdLiveModels({ try await Things.read(from: $0, orderBy: .ascending(\.$title)) }) var things
    @EnvironmentObject private var model: Model

    var body: some View {
        if things.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(things.results) { thing in
                        NavigationLink(destination: {
                            ThingsView(thing: thing)
                        }, label: {
                            ThingsRow(thing: thing)
                        })
//                        NavigationLink(tag: thing.title ?? thing.upc ?? "", selection: $model.selectedThingID) {
//                            ThingsView(thing: thing)
//                        } label: {
//                            ThingsRow(thing: thing)
//                        }
                    }
                }
            }
        } else {
            Group {
                ProgressView()
                Text("Loading")
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        ThingsList().navigationTitle(LocalizedStringKey(stringLiteral: "nav.things"))
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
