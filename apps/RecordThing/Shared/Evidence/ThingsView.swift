//
//  DocumentTypeView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct ThingsView: View {
    @Environment(\.blackbirdDatabase) private var database

    var thing: Things
    @State var thingEvidence = Evidence.LiveResults()
    var evidenceUpdater = Evidence.ArrayUpdater()

    @State private var presentingOrderPlacedSheet = false
    @State private var presentingSecurityAlert = false
    @EnvironmentObject private var model: Model
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedEvidenceID: Evidence.ID?
    @State private var topmostEvidenceID: Evidence.ID?
    @Namespace private var namespace
    
    #if APPCLIP
    @State private var presentingAppStoreOverlay = false
    #endif

    var body: some View {
        container
            #if os(macOS)
            .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
            .background()
            .navigationTitle(thing.title ?? "<title>")
            .toolbar {
                Text(" ")
//                ProductFavoriteButton()
//                    .environmentObject(model)
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
    }
    
    var container: some View {
        ZStack {
            ScrollView {
                content
                    #if os(macOS)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    #endif
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            
            if thingEvidence.didLoad {
                ForEach(thingEvidence.results) { evidence in
                    let presenting = selectedEvidenceID ?? "" == evidence.id
                    EvidenceCard(evidence: evidence, presenting: presenting, closeAction: deselectEvidence)
                        .matchedGeometryEffect(id: evidence.id, in: namespace, isSource: presenting)
                        .aspectRatio(0.75, contentMode: .fit)
                        .shadow(color: Color.black.opacity(presenting ? 0.2 : 0), radius: 20, y: 10)
                        .padding(20)
                        .opacity(presenting ? 1 : 0)
                        .zIndex(topmostEvidenceID == evidence.id ? 1 : 0)
                        .accessibilityElement(children: .contain)
                        .accessibility(sortPriority: presenting ? 1 : 0)
                        .accessibility(hidden: !presenting)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            evidenceUpdater.bind(from: database, to: $thingEvidence) {
                try await Evidence.read(from: $0, matching: \.$thing_id == thing.id, orderBy: .ascending(\.$id))
            }
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            ThingsHeaderView(thing: thing)
            
            VStack(alignment: .leading) {
                Text("nav.evidence",
                     tableName: "evidence",
                     comment: "Evidence in a smoothie. For languages that have different words for \"Ingredient\" based on semantic context.")
                    .font(Font.title).bold()
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16, alignment: .top)], alignment: .center, spacing: 16) {
                    ForEach(thingEvidence.results) { evidence in
                        let presenting = selectedEvidenceID ?? "" == evidence.id
                        Button(action: { select(evidence: evidence) }) {
                            EvidenceGraphic(evidence: evidence, title: Evidence.CardTitle(), style: presenting ? .cardFront : .thumbnail)
                                .matchedGeometryEffect(
                                    id: evidence.id,
                                    in: namespace,
                                    isSource: !presenting
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.squishable(fadeOnPress: false))
                        .aspectRatio(1, contentMode: .fit)
                        .zIndex(topmostEvidenceID == evidence.id ? 1 : 0)
                        .accessibility(label: Text("\(evidence.name) Ingredient",
                                                   comment: "Accessibility label for collapsed ingredient card in smoothie overview"))
                    }
                }
            }
            .padding()

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
    
    func select(evidence: Evidence) {
        topmostEvidenceID = evidence.id
        withAnimation(.openCard) {
            selectedEvidenceID = evidence.id
        }
    }
    
    func deselectEvidence() {
        withAnimation(.closeCard) {
            selectedEvidenceID = nil
        }
    }

}


#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
    @Previewable @StateObject var model = Model()

    NavigationStack {
        ThingsView(thing: .Sports)
    }
}

//struct ThingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
//        @Previewable @StateObject var model = Model()
//
//        Group {
//            NavigationView {
//                ThingsView(thing: .Sports)
//            }
//            
//            ForEach([Things.Pet, .Room, .Furniture]) { thing in
//                ThingsView(thing: thing)
//                    .previewLayout(.sizeThatFits)
//                    .frame(height: 700)
//            }
//        }
//        .environment(\.blackbirdDatabase, database)
//        .environmentObject(Model())
//    }
//}
