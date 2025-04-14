//
//  EvidenceTypeList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 16.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

/*
public struct TestList: View {
    @BlackbirdLiveModels({ try await TestCustomDecoder.read(from: $0, orderBy: .ascending(\.$name)) }) public var types
    @EnvironmentObject private var model: Model
    
    public var body: some View {
        if types.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(types.results) { type in
                        NavigationLink(destination: {
                            Text(type.name)
                            Text(type.thumbnail.absoluteString)
                        }, label: {
                            Text(type.name)
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

#if DEBUG
#Preview {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        TestList().navigationTitle(LocalizedStringKey(stringLiteral: "test"))
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
#endif
*/
