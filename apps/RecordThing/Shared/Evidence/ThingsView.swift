//
//  DocumentTypeView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird
import RecordLib


struct ThingsView: View {
    @Environment(\.blackbirdDatabase) private var database
    @State var evidenceUpdater = Evidence.ArrayUpdater()

    var thing: Things
    @State var thingEvidence = Evidence.LiveResults()

    @State private var presentingOrderPlacedSheet = false
    @State private var presentingSecurityAlert = false
    @EnvironmentObject private var model: Model
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedEvidenceID: Evidence.ID?
    
    #if APPCLIP
    @State private var presentingAppStoreOverlay = false
    #endif

    @State private var showingActionSheet = false
    
    var body: some View {
        GridWithPopup(results: $thingEvidence.results, didLoad: $thingEvidence.didLoad, selectedID: $selectedEvidenceID, headerView: {
            VStack(alignment: .leading) {
                ThingsHeaderView(thing: thing)
                Text(LocalizedStringKey(stringLiteral: "nav.evidence"),
                     tableName: "evidence",
                     comment: "Evidence in a smoothie. For languages that have different words for \"Ingredient\" based on semantic context.")
                .font(Font.title).bold()
                .foregroundStyle(.secondary)
            }

        }, bottomBar: { bottomBar }, itemContent: { item, isPresenting, close, flipCard in
            EvidenceGraphic(evidence: item, title: Evidence.CardTitle(), style: isPresenting ? .cardFront : .thumbnail, closeAction: close, flipAction: flipCard)
        })
            .padding()
            #if os(macOS)
            .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
            .background()
            .navigationTitle(thing.title ?? "<title>")
            .toolbar {
//                ProductFavoriteButton()
//                    .environmentObject(model)
                Menu {
                    Button(action: { /* Share action */ }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { /* Export action */ }) {
                        Label("Export", systemImage: "arrow.up.doc")
                    }
                    
                    Divider()
                    
                    Button(action: { /* Edit action */ }) {
                        Label("Edit Details", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { /* Delete action */ }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
            }
            .sheet(isPresented: $presentingOrderPlacedSheet) {
            }
            .alert(isPresented: $presentingSecurityAlert) {
                Alert(
                    title: Text("Payments Disabled",
                                comment: "Title of alert dialog when payments are disabled"),
                    message: Text("The RecordThing QR code was scanned too far from the shop, payments are disabled for your protection.",
                                  comment: "Explanatory text of alert dialog when payments are disabled"),
                    dismissButton: .default(Text("OK",
                                                 comment: "OK button of alert dialog when payments are disabled"))
                )
            }
            .onAppear {
                evidenceUpdater.bind(from: database, to: $thingEvidence) {
                    try await Evidence.read(from: $0, matching: \.$thing_id == thing.id, orderBy: .ascending(\.$id))
                }
            }
    }
    
    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
        }
        .background(.bar)
    }
}

#if DEBUG
struct DemoGridView: View {
    @Environment(\.blackbirdDatabase) private var database
    @State var evidenceUpdater = Evidence.ArrayUpdater()

    var thingID: Things.ID
    @State var thingEvidence = Evidence.LiveResults()

    @State private var selectedEvidenceID: Evidence.ID?
    
    var body: some View {
        GridWithPopup(results: $thingEvidence.results, didLoad: $thingEvidence.didLoad, selectedID: $selectedEvidenceID, headerView: {
            EmptyView() }, bottomBar: { EmptyView() }, itemContent: { item, isPresenting, close, flipCard in
            EvidenceGraphic(evidence: item, title: Evidence.CardTitle(), style: isPresenting ? .cardFront : .thumbnail, closeAction: close, flipAction: flipCard)
        })
            #if os(macOS)
            .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
            .padding()
            .onAppear {
                evidenceUpdater.bind(from: database, to: $thingEvidence) {
                    try await Evidence.read(from: $0, matching: \.$thing_id == thingID, orderBy: .ascending(\.$id))
                }
            }
    }
}



#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationStack {
        ThingsView(thing: .Jewelry)
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}

struct EvidenceGrid_Previews: PreviewProvider {
    static var previews: some View {
        @Previewable @StateObject var datasource = AppDatasource.shared
        @Previewable @StateObject var model = Model(loadedLangConst: "en")
        @Previewable @State var list: [Evidence] = [
            .avocado,
            .almondMilk,
            .coconut
        ]
        @Previewable @State var selectedEvidenceID: Evidence.ID?


        DemoGridView(thingID: "2vlzWlLwaDYUS7T3a6VSUrF9xU6")
//        Group {
//            GridWithPopup(results: $list/*.constant(Evidence.all)*/, didLoad: .constant(true), selectedID: $selectedEvidenceID, headerView: { EmptyView() }, bottomBar: { EmptyView() },
//              itemContent: { item, isPresenting, close, flipCard in
//                EvidenceGraphic(evidence: item, title: Evidence.CardTitle(), style: isPresenting ? .cardFront : .thumbnail, closeAction: close, flipAction: flipCard)
//            })
//        }
        .environment(\.blackbirdDatabase, datasource.db)
        .environmentObject(model)
        .previewDisplayName("Evidence Grid")
    }
}
#endif
