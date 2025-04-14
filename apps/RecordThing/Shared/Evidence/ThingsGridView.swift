import SwiftUI
import Blackbird
import os
import RecordLib

/// A view that displays a grid of Things cards grouped by month
public struct ThingsGridView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.things-grid")
    
    // State
    @State private var things: [Things] = []
    @State private var groupedThings: [String: [Things]] = [:]
    @State private var isLoading = true
    @State private var error: Error?
    
    // Design system
    let designSystem: DesignSystemSetup
    
    // Callbacks
    let onThingSelected: (Things) -> Void
    
    // MARK: - Initialization
    
    public init(
        designSystem: DesignSystemSetup = .light,
        onThingSelected: @escaping (Things) -> Void
    ) {
        self.designSystem = designSystem
        self.onThingSelected = onThingSelected
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Error loading things")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(groupedThings.keys.sorted(by: >), id: \.self) { month in
                            if let things = groupedThings[month] {
                                monthSection(month: month, things: things)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadThings()
        }
    }
    
    // MARK: - UI Components
    
    /// Section for a group of things by month
    private func monthSection(month: String, things: [Things]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month header
            Text(month)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .padding(.leading, 4)
            
            // Grid of things, 2 per row
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(things) { thing in
                    thingCard(thing)
                }
            }
        }
    }
    
    /// Card for a single thing
    private func thingCard(_ thing: Things) -> some View {
        Button(action: {
            onThingSelected(thing)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Thing image or placeholder
                ZStack {
                    if let imageName = thing.evidence_type_name {
                        Image(systemName: imageName)
                            .font(.system(size: 30))
                            .foregroundColor(.accentColor)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .frame(height: 120)
                .cornerRadius(designSystem.cornerRadius)
                
                // Thing title
                Text(thing.title ?? "Untitled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Thing category
                if let category = thing.category {
                    Text(category)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    /// Load things from the database and group them by month
    private func loadThings() async {
        do {
            guard let db = AppDatasource.shared.db else {
                throw NSError(domain: "ThingsGridView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not available"])
            }
            
            let rows: [Dictionary] = try await db.query("""
                SELECT * FROM things
                ORDER BY created_at DESC
            """)
            
            things = rows.compactMap { row in
                try? Things(from: row as! Decoder)
            }
            
            // Group things by month
            groupedThings = Dictionary(grouping: things) { thing in
                guard let date = thing.created_at else { return "Unknown" }
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: date)
            }
            
            isLoading = false
            logger.debug("Loaded \(things.count) things")
        } catch {
            self.error = error
            isLoading = false
            logger.error("Error loading things: \(error)")
        }
    }
}

// MARK: - Previews
#if DEBUG
struct ThingsGridView_Previews: PreviewProvider {
    static var previews: some View {
        ThingsGridView { thing in
            print("Selected thing: \(thing.title ?? "Untitled")")
        }
        .previewDisplayName("Things Grid")
    }
}
#endif 
