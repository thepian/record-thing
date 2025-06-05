//
//  StrategistsView.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import Blackbird
import RecordLib

struct StrategistsView: View {
    var strategist: Strategists
    @EnvironmentObject private var model: Model
    
    // Load evidence related to this strategist
    @BlackbirdLiveModels var evidence: Blackbird.LiveResults<Evidence>
    
    init(strategist: Strategists) {
        self.strategist = strategist
        self._evidence = BlackbirdLiveModels({ db in
            try await Evidence.read(
                from: db,
                where: "strategist_account_id = ? AND strategist_id = ?",
                orderBy: .descending(\.$created_at),
                strategist.account_id, strategist.id
            )
        })
    }
    
    var container: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(strategist.title ?? "Untitled Strategy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let description = strategist.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags
                    if !strategist.tagsArray.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(strategist.tagsArray, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Evidence section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Related Evidence")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if evidence.didLoad {
                        if evidence.results.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No evidence yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Share content from other apps to add evidence to this strategic focus area.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(evidence.results) { evidenceItem in
                                    EvidenceRowView(evidence: evidenceItem)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
    }

    var body: some View {
        container
            .padding()
            #if os(macOS)
            .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            #endif
            .background()
            .navigationTitle(strategist.title ?? "Strategy")
            .toolbar {
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
    }
}

// Simple evidence row view for the strategist
struct EvidenceRowView: View {
    let evidence: Evidence
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(evidence.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let data = evidence.data {
                    Text(data)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if evidence.local_file != nil {
                Image(systemName: "photo")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "link")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    let strategist = Strategists(
        id: "test123",
        account_id: "acc123",
        title: "AI & Machine Learning Strategy",
        description: "Exploring the latest developments in artificial intelligence and machine learning technologies for strategic advantage.",
        tags: "[\"AI\", \"ML\", \"Strategy\", \"Technology\"]",
        created_at: Date(),
        updated_at: Date()
    )
    
    @Previewable @StateObject var datasource = AppDatasource.shared
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    NavigationView {
        StrategistsView(strategist: strategist)
    }
    .environment(\.blackbirdDatabase, datasource.db)
    .environmentObject(model)
}
