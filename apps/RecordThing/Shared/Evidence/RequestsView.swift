//
//  DocumentTypeView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird

struct RequestsView: View {
    @Environment(\.blackbirdDatabase) private var database

    var request: Requests
    @State var requestEvidence = Evidence.LiveResults()
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
            .navigationTitle(request.title)
//            .toolbar {
//                ProductFavoriteButton()
//                    .environmentObject(model)
//            }
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
            
            if requestEvidence.didLoad {
                ForEach(requestEvidence.results) { evidence in
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
            evidenceUpdater.bind(from: database, to: $requestEvidence) {
                try await Evidence.read(from: $0, matching: \.$request_id == request.id, orderBy: .ascending(\.$id))
            }
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            RequestsHeaderView(request: request)
            
            /**
             @BlackbirdColumn var id: String  // KSUID
             @BlackbirdColumn var account_id: String
             
             // Product identifiers
             @BlackbirdColumn var upc: String?  // Universal Product Code
             @BlackbirdColumn var asin: String?  // Amazon Standard Identification Number
             @BlackbirdColumn var elid: String?  // Electronic Product Identifier
             
             // Product details
             @BlackbirdColumn var brand: String?
             @BlackbirdColumn var model: String?
             @BlackbirdColumn var color: String?
             @BlackbirdColumn var tags: String?  // JSON array
             @BlackbirdColumn var category: String?
             
             // Type references
             @BlackbirdColumn var product_type: Int?
             @BlackbirdColumn var document_type: Int?
             
             // Description fields
             @BlackbirdColumn var title: String?
             @BlackbirdColumn private var description: String?  // Backing field for description
             */
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(stringLiteral: "nav.evidence"),
                     tableName: "evidence",
                     comment: "Evidence in a smoothie. For languages that have different words for \"Ingredient\" based on semantic context.")
                    .font(Font.title).bold()
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16, alignment: .top)], alignment: .center, spacing: 16) {
                    ForEach(requestEvidence.results) { evidence in
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
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    Group {
        NavigationStack {
            RequestsView(request: .Electronics)
        }
    }
    .environment(\.blackbirdDatabase, database)
    .environmentObject(Model())
}
