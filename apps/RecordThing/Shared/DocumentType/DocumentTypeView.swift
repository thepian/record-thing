//
//  DocumentTypeView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct DocumentTypeView: View {
    var document: DocumentType
    
    @State private var presentingOrderPlacedSheet = false
    @State private var presentingSecurityAlert = false
    @EnvironmentObject private var model: Model
    @Environment(\.colorScheme) private var colorScheme
    
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
            .navigationTitle(document.fullName)
            .toolbar {
                ProductFavoriteButton()
                    .environmentObject(model)
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
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            DocumentTypeHeaderView(document: document)
                
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


#Preview {
    Group {
        NavigationView {
            DocumentTypeView(document: .Receipt)
        }
        
        ForEach([DocumentType.Document, .Receipt, .Card]) { document in
            DocumentTypeView(document: document)
                .previewLayout(.sizeThatFits)
                .frame(height: 700)
        }
    }
    .environmentObject(Model())
}
