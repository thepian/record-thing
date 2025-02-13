//
//  DocumentTypeList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct DocumentTypeList: View {
    
    @BlackbirdLiveModels({ try await DocumentType.read(from: $0, orderBy: .ascending(\.$name)) }) var types
    @EnvironmentObject private var model: Model

    var body: some View {
//        if types.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(types.results) { docType in
                        NavigationLink(destination: {
                            DocumentTypeView(document: docType)
                        }, label: {
                            DocumentTypeRow(document: docType)
                        })
//                        NavigationLink(tag: docType.name, selection: $model.selectedTypeID) { }
                        .onChange(of: model.selectedTypeID) { newValue in
                            // Need to make sure the Product exists.
                //                        guard let smoothieID = newValue, let product = ProducType(for: smoothieID) else { return }
                //                        proxy.scrollTo(product.id)
                //                        model.selectedTypeID = product.id
                        }
                        .swipeActions {
                            Button {
                                withAnimation {
                //                                    model.toggleFavorite(smoothieID: product.id)
                                }
                            } label: {
                                Label {
                                    Text("Favorite", comment: "Swipe action button in document list")
                                } icon: {
                                    Image(systemName: "heart")
                                }
                            }
                            .tint(.accentColor)
                        }


                    }
                }
//                .accessibilityRotor("Documents", entries: types, entryLabel: \.fullName)
//                .accessibilityRotor("Favorite Documents", entries: types.filter { model.isFavorite(document: $0) }, entryLabel: \.fullName)
//                    .searchable(text: $model.searchString) {
//                        ForEach(model.searchSuggestions) { suggestion in
//                            Text(suggestion.name).searchCompletion(suggestion.name)
//                        }
//                    }
            }
//        } else {
//            Group {
//                ProgressView()
//                Text("Loading")
//            }
//        }
    }
    
    
    // TODO support hardcoded
//    var documents: [DocumentType]

    
//    @EnvironmentObject private var model: Model
    
//    var listedDocuments: [DocumentType] {
//        types.results
//            .filter { $0.matches(model.searchString) }
//            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
//    }
}

#Preview {
    @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
    @Previewable @StateObject var model = Model(loadedLangConst: "en")
    
    NavigationView {
        DocumentTypeList()
            .navigationTitle(Text("Document Type", comment: "Title of the 'menu' app section showing the menu of available document types"))
    }
        .environment(\.blackbirdDatabase, database)
        .environmentObject(model)
}
