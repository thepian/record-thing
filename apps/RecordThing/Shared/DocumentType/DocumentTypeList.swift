//
//  DocumentTypeList.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import Blackbird

struct DocumentTypeList: View {
    
    @Binding var results = Blackbird.LiveResults<DocumentType>()
    
    var body: some View {
        if types.didLoad {
            ScrollViewReader { proxy in
                List {
                    ForEach(types.results) { docType in
                        NavigationLink(tag: docType.name, selection: $model.selectedProductID) {
                            ProductTypeView(document: docType)
                        } label: {
                            DocumentTypeRow(document: docType)
                        }
                        .onChange(of: model.selectedProductID) { newValue in
                            // Need to make sure the Product exists.
    //                        guard let smoothieID = newValue, let product = ProducType(for: smoothieID) else { return }
    //                        proxy.scrollTo(product.id)
    //                        model.selectedProductID = product.id
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
                .accessibilityRotor("Documents", entries: documents, entryLabel: \.fullName)
                .accessibilityRotor("Favorite Documents", entries: documents.filter { model.isFavorite(document: $0) }, entryLabel: \.fullName)
                .searchable(text: $model.searchString) {
                    ForEach(model.searchSuggestions) { suggestion in
                        Text(suggestion.name).searchCompletion(suggestion.name)
                    }
                }

            }
        }
    }
    
    
    // TODO support hardcoded
//    var documents: [DocumentType]

    @EnvironmentObject private var model: Model
    
    var listedDocuments: [DocumentType] {
        results
//            .filter { $0.matches(model.searchString) }
            .sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending })
    }
}

#Preview {
    DocumentTypeList(results: DocumentType.all())
}
