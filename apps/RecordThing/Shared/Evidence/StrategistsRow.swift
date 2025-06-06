//
//  StrategistsRow.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import RecordLib

struct StrategistsRow: View {
    var strategist: Strategists
    @EnvironmentObject private var model: Model

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategist.title ?? "Untitled Strategy")
                    .font(.headline)
                    .lineLimit(2)
                
                if let description = strategist.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                if !strategist.tagsArray.isEmpty {
                    HStack {
                        ForEach(strategist.tagsArray.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        if strategist.tagsArray.count > 3 {
                            Text("+\(strategist.tagsArray.count - 3)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    StrategistsRow(strategist: Strategists.AIStrategy)
        .environmentObject(model)
        .padding()
}
