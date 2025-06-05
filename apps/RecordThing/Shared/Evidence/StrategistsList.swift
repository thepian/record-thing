//
//  StrategistsList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird
import RecordLib

struct StrategistsList: View {
    
    @BlackbirdLiveModels({ try await Strategists.read(from: $0, orderBy: .ascending(\.$title)) }) var strategists
    @EnvironmentObject private var model: Model

    var body: some View {
        if strategists.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(strategists.results) { strategist in
                        NavigationLink(destination: {
                            StrategistsView(strategist: strategist)
                        }, label: {
                            StrategistsRow(strategist: strategist)
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
        StrategistsList()
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
