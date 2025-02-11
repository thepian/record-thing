//
//  RequestsList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct RequestsList: View {
    
    @BlackbirdLiveModels({ try await Requests.read(from: $0, orderBy: .ascending(\.$url)) }) var requests
    @EnvironmentObject private var model: Model

    var body: some View {
        if requests.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(requests.results) { request in
                        NavigationLink(destination: {
                            RequestsView(request: request)
                        }, label: {
                            RequestsRow(request: request)
                        })
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
        RequestsList().navigationTitle("Navigation Title")
    }
    .environment(\.blackbirdDatabase, database)
    .environmentObject(model)
}
