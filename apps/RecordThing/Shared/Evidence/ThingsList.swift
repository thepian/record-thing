//
//  ThingsList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

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
    @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
    @Previewable @StateObject var model = Model()

    NavigationView {
        ThingsList().navigationTitle("nav.things")
    }
    .task {
        // Initialize translations when app starts
        await DynamicLocalizer.shared.registerTranslations(from: database)
    }
    .environment(\.blackbirdDatabase, database)
    .environmentObject(model)
}
