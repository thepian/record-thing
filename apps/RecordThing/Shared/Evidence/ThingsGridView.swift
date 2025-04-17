import SwiftUI
import Blackbird
import os
import RecordLib

public struct ThingsGridCard: View {
    @State var thing: Things
    
    let df: DateFormatter
    
    public init(thing: Things) {
        _thing = State(wrappedValue: thing)
        
        df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 32)
            .foregroundColor(Color.white)
            .border(Color.gray)
            .frame(width: 120, height: 80)
            .overlay {
                VStack {
                    Text(thing.title ?? "<title>")
                    Text(df.string(from: thing.created_at ?? Date()))
                }
            }
    }
}

public struct ThingsDates: View {
    @Environment(\.blackbirdDatabase) var db

    var df: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return df
    }
    
    public var body: some View {
        VStack {
            Button(action: {
                Task {
                    if let db = db {
                        let dates = try await Things.query(in: db, columns: [\.$created_at], matching: \.$created_at != nil)
                        print("Dates: \(dates.count)")
                        for d in dates {
                            if let created_at = d[\.$created_at] {
                                print(df.string(from: created_at))
                            }
                        }
                    }
                }
            }) {
                Text("Calc")
            }
//            if let rows = dates.result {
//                List {
//                    ForEach(rows) { row in
//                        if let created_at = row[\.$created_at] {
//                            Text(df.string(from: created_at))
//                        } else {
//                            Text("nil")
//                        }
//                    }
//                }
//                .animation(.default, value: rows)
//            } else {
//                ProgressView()
//            }
        }
//        .onAppear {
//            dates.bind(to: db)
//        }

    }
}

public struct ThingsSubgridView: View {
    @StateObject private var viewModel: AssetsViewModel
    @State private var things: [Things] = []
    @State private var columns: Int
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.things-grid")
    
    // Design system
    let designSystem: DesignSystemSetup
    
    // Data
    let group: AssetGroup
    
    // Callbacks
    let onThingSelected: (Things) -> Void
    
    // Orientation
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    // MARK: - Initialization
    
    public init(
        viewModel: AssetsViewModel,
        group: AssetGroup,
        designSystem: DesignSystemSetup = .light,
        columns: Int = 1,
        onThingSelected: @escaping (Things) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.group = group
        self.designSystem = designSystem
        self._columns = State(initialValue: columns)
        self.onThingSelected = onThingSelected
    }
    
    public var body: some View {
        LazyVGrid(columns: gridColumns(), spacing: 16) {
            ForEach(things) { thing in
                thingCard(thing)
            }
        }
        .onAppear {
            loadThings()
        }
    }
    
    private func gridColumns() -> [GridItem] {
        var baseColumns = viewModel.isLandscape ? Int(Double(columns) * 1.5) : columns
        // consider size class .regular landscape to have columns * 2
        #if os(iOS)
        if horizontalSizeClass == .regular {
            baseColumns = Int(Double(baseColumns) * 1.5)
        }
        #endif
        
        return Array(repeating: GridItem(.flexible()), count: max(1, baseColumns))
    }
    
    private func loadThings() {
        guard let db = viewModel.db else {
            logger.error("Database not available")
            return
        }
        
        Task {
            do {
                // Query things within the date range
                let results = try await Things.read(
                    from: db,
                    matching: \.$created_at >= group.from && \.$created_at < group.to
                )
                
                await MainActor.run {
                    things = results
                    logger.debug("Loaded \(things.count) things for group \(group.title)")
                }
            } catch {
                logger.error("Failed to load things: \(error)")
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
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            // Thing category
                            if let category = thing.category {
                                Text(category)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .shadow(color: designSystem.shadowColor, radius: designSystem.shadowRadius)
                                    .lineLimit(1)
                                    .padding(designSystem.cardSpacing)
                            }
                        }
                    }
                }
                .frame(minWidth: designSystem.assetsCardWidth)
                .cornerRadius(designSystem.cornerRadius)
                
                // Thing title
                HStack {
                    Text(thing.title ?? "Untitled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: designSystem.assetsCardWidth)
                    Spacer()
                }
                .frame(minWidth: designSystem.assetsCardWidth)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A view that displays a grid of Things cards grouped by time periods
public struct ThingsGridView: View {
    @StateObject private var viewModel: AssetsViewModel
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.things-grid")
    
    // Design system
    let designSystem: DesignSystemSetup
    
    // Callbacks
    let onThingSelected: (Things) -> Void
    
    @State private var columns: Int

    // Size class
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    // MARK: - Initialization
    
    public init(
        viewModel: AssetsViewModel,
        designSystem: DesignSystemSetup = .light,
        columns: Int = 1,
        onThingSelected: @escaping (Things) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.designSystem = designSystem
        self.columns = columns
        self.onThingSelected = onThingSelected
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let error = viewModel.error {
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
                        ForEach(viewModel.assetGroups) { group in
                            timeSection(group: group)
                            ThingsSubgridView(
                                viewModel: viewModel,
                                group: group,
                                designSystem: designSystem,
                                columns: columns,
                                onThingSelected: onThingSelected
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            logger.debug("loading dates")
            viewModel.loadDates()
        }
    }
    
    // MARK: - UI Components
    
    /// Section for a group of things by time period
    private func timeSection(group: AssetGroup) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time period header
            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                // Date range subtitle
                /*
                let formatter = DateFormatter()
//                formatter.dateStyle = .medium
//                formatter.timeStyle = .none
                
                Text("\(formatter.string(from: group.from)) - \(formatter.string(from: group.to))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                 */
            }
            .padding(.leading, 4)
        }
    }
}

// MARK: - Previews
#if DEBUG
struct ThingsGridView_Previews: PreviewProvider {
    static var previews: some View {
        @Previewable @StateObject var datasource = AppDatasource.shared
        @Previewable @StateObject var model = Model(loadedLangConst: "en")
        @Previewable @StateObject var viewModel = AssetsViewModel(db: AppDatasource.shared.db)

        ThingsGridView(viewModel: viewModel, columns: 2) { thing in
            print("Selected thing: \(thing.title ?? "Untitled")")
        }
        .environment(\.blackbirdDatabase, datasource.db)
        .environmentObject(model)
        .previewDisplayName("Things Grid")
        
        ThingsDates()
            .environment(\.blackbirdDatabase, datasource.db)
            .environmentObject(model)
            .previewDisplayName("Things Dates")
    }
}
#endif 
