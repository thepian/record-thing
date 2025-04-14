//
//  EvidenceTypeList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird
import RecordLib

struct EvidenceTypeList: View {
    @BlackbirdLiveModels({ try await EvidenceType.read(from: $0, orderBy: .ascending(\.$name)) }) var types
    @EnvironmentObject private var model: Model
    
    var grouped = false
    
    func groupByCategory(_ items: [EvidenceType]) -> [(String, [EvidenceType])] {
        let grouped = Dictionary(grouping: items, by: { $0.group })
        return grouped.sorted(by: { $0.key < $1.key })
    }

    var body: some View {
        if types.didLoad {
            ScrollViewReader { proxy in
                List {
                    if grouped {
                        ForEach(groupByCategory(types.results), id: \.0) { pair in
                            Section(header: Text(pair.0)) {
                                ForEach(pair.1) {
                                    type in
                                    NavigationLink(destination: {
                                        EvidenceTypeView(type: type)
                                    }, label: {
                                        EvidenceTypeRow(type: type)
                                    })
                                }
                            }
                        }
                    } else {
                        ForEach(types.results) { type in
                            NavigationLink(destination: {
                                EvidenceTypeView(type: type)
                            }, label: {
                                EvidenceTypeRow(type: type)

                            })
                        }
                    }
                }
//                .listStyle(InsetGroupedListStyle())
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
        EvidenceTypeList().navigationTitle(LocalizedStringKey(stringLiteral: "nav.types"))
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
