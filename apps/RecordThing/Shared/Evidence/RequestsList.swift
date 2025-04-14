//
//  RequestsList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird
import RecordLib

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
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        RequestsList().navigationTitle(LocalizedStringKey(stringLiteral: "nav.requests"))
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
