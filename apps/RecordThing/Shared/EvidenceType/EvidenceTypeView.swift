//
//  EvidenceTypeView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.09.2024.
//  Copyright © 2025 Thepia.. All rights reserved.
//

import SwiftUI
import RecordLib

struct EvidenceTypeView: View {
    var type: EvidenceType
    
    @State private var presentingOrderPlacedSheet = false
    @State private var presentingSecurityAlert = false
    @EnvironmentObject private var model: Model
    @Environment(\.colorScheme) private var colorScheme
    
    @Namespace private var namespace
    
    #if APPCLIP
    @State private var presentingAppStoreOverlay = false
    #endif
    
    @State private var showingActionSheet = false

    var body: some View {
        container
            #if os(macOS)
            .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
            .background()
            .navigationTitle(type.fullName)
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
            EvidenceTypeHeaderView(type: type)
                
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


#Preview(traits: .sizeThatFitsLayout) {
    Group {
        NavigationView {
            EvidenceTypeView(type: .Electronics)
        }
        
        ForEach([EvidenceType.Electronics, .Pet, .Room]) { type in
            EvidenceTypeView(type: type)
                .frame(height: 700)
        }
    }
    .environmentObject(Model(loadedLangConst: "en"))
}
