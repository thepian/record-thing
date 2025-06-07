import Blackbird
import RecordLib
import SwiftUI
import os

public struct ThingsCard: View {
  public var thing: Things
  public var pieces: [EvidencePiece]
  public var designSystem: DesignSystemSetup
  public var title: Evidence.CardTitle
  public var style: Style
  public var closeAction: () -> Void = {}
  public var flipAction: () -> Void = {}

  public var thumbnailCrop = Evidence.Crop()
  public var cardCrop = Evidence.Crop()

  public enum Style {
    case cardFront
    case cardBack
    case thumbnail
  }

  public init(
    thing: Things,
    pieces: [EvidencePiece],
    title: Evidence.CardTitle = Evidence.CardTitle(),
    designSystem: DesignSystemSetup,
    style: Style,
    closeAction: @escaping () -> Void = {},
    flipAction: @escaping () -> Void = {},
    thumbnailCrop: Evidence.Crop = Evidence.Crop(),
    cardCrop: Evidence.Crop = Evidence.Crop()
  ) {
    self.thing = thing
    self.pieces = pieces
    self.title = title
    self.designSystem = designSystem
    self.style = style
    self.closeAction = closeAction
    self.flipAction = flipAction
    self.thumbnailCrop = thumbnailCrop
    self.cardCrop = cardCrop
  }

  public var displayingAsCard: Bool {
    style == .cardFront || style == .cardBack
  }

  public var shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

  public var body: some View {
    let minWidth = designSystem.assetsCardWidth

    VStack(alignment: .leading, spacing: 8) {
      // Card
      ZStack {
        Color.clear
          .frame(minWidth: minWidth, minHeight: minWidth)

        imageView

        cameraNav

        stackView

        if style == .cardFront {
          cardControls(for: .front)
            .foregroundStyle(title.color)
            .opacity(title.opacity)
            .blendMode(title.blendMode)
        }

        if style == .cardBack {
          ZStack {
            //                    if let nutritionFact = evidence.nutritionFact { NutritionFactView(nutritionFact: nutritionFact).padding(.bottom, 70) }
            //                    cardControls(for: .back)
          }
          .background(.thinMaterial)
        }
      }

      // Thing title
      HStack {
        Text(thing.title ?? "Untitled")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)
          .frame(maxWidth: minWidth)
        Spacer()
      }
      .frame(minWidth: minWidth)
    }
    .frame(minWidth: minWidth, maxWidth: 400, maxHeight: 500)
    .compositingGroup()
    .background()
    .clipShape(shape)
    .overlay {
      shape
        .inset(by: 0.5)
        .stroke(.quaternary, lineWidth: 0.5)
    }
    .contentShape(shape)
    .accessibilityElement(children: .contain)
  }

  public var imageView: some View {
    GeometryReader { geo in
      Group {
        if let imageName = thing.evidence_type_name {
          Image(systemName: imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .font(.system(size: 30))
            .foregroundColor(.accentColor)
        } else {
          Rectangle()
            .fill(Color.secondary.opacity(0.1))
            .aspectRatio(1, contentMode: .fit)
        }
      }
      //            .frame(width: geo.size.width, height: geo.size.height)
      //            .scaleEffect(displayingAsCard ? cardCrop.scale : thumbnailCrop.scale)
      //            .offset(displayingAsCard ? cardCrop.offset : thumbnailCrop.offset)
      //            .frame(width: geo.size.width, height: geo.size.height)
      .scaleEffect(x: style == .cardBack ? -1 : 1)
      .accessibility(hidden: true)
    }
  }

  var stackView: some View {
    ImageCardStack(pieces: pieces, designSystem: designSystem)
  }

  var cameraNav: some View {
    Group {
      if style == .cardFront {
        VStack(alignment: .leading) {
          Spacer()
          HStack {
            Spacer()
            Button(action: {
              Task {
                // await permitAlert()
                print("camera")
              }
            }) {
              Image(systemName: "camera.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
                .padding()

            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  public var titleView: some View {
    Text((thing.title ?? "<Untitled>").uppercased())
  }

  public func cardControls(for side: FlipViewSide) -> some View {
    VStack {
      if side == .front {
        CardActionButton(label: "Close", systemImage: "xmark.circle.fill", action: closeAction)
          .scaleEffect(displayingAsCard ? 1 : 0.5)
          .opacity(displayingAsCard ? 1 : 0)
      }
      Spacer()
      CardActionButton(
        label: side == .front ? "Open Nutrition Facts" : "Close Nutrition Facts",
        systemImage: side == .front ? "info.circle.fill" : "arrow.left.circle.fill",
        action: flipAction
      )
      .scaleEffect(displayingAsCard ? 1 : 0.5)
      .opacity(displayingAsCard ? 1 : 0)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

}

public struct ThingsSubgridView: View {
  @StateObject private var viewModel: AssetsViewModel
  @StateObject private var evidenceViewModel: EvidenceViewModel
  @State private var columns: Int
  @State private var adaptiveColumns: Bool = false
  @Namespace private var namespace

  // Logger for debugging
  private let logger = Logger(subsystem: "com.record-thing", category: "ui.things-grid")

  // Design system
  let designSystem: DesignSystemSetup

  // Data
  let groupIndex: Int

  // Callbacks
  let onThingSelected: (Things) -> Void

  // Selected thing
  @Binding var sidebarThing: Things?
  @Binding var popupCard: Things?

  @Environment(\.blackbirdDatabase) private var database
  @State var assetsLive = Blackbird.LiveResults<Asset>()

  @State private var selectedID: Things.ID?

  // Orientation
  #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  // MARK: - Initialization

  public init(
    viewModel: AssetsViewModel,
    evidenceViewModel: EvidenceViewModel,
    groupIndex: Int,
    designSystem: DesignSystemSetup = .light,
    columns: Int = 1,
    sidebarThing: Binding<Things?>,
    popupCard: Binding<Things?>,
    onThingSelected: @escaping (Things) -> Void
  ) {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self._evidenceViewModel = StateObject(wrappedValue: evidenceViewModel)
    self.groupIndex = groupIndex
    self.designSystem = designSystem
    self._columns = State(initialValue: columns)
    self._sidebarThing = sidebarThing
    self._popupCard = popupCard
    self.onThingSelected = onThingSelected
  }

  public var body: some View {
    GridWithPopup(
      results: Binding(
        get: { viewModel.assetGroups[groupIndex].assets },
        set: { newAssets in
          if groupIndex < viewModel.assetGroups.count {
            viewModel.updateGroupAssets(
              groupId: viewModel.assetGroups[groupIndex].id,
              assets: newAssets
            )
          }
        }
      ),
      didLoad: Binding(
        get: { viewModel.assetGroups[groupIndex].didLoad },
        set: { _ in }
      ),
      selectedID: $selectedID,
      headerView: { EmptyView() },
      bottomBar: { EmptyView() },
      itemContent: { item, isPresenting, close, flipCard in
        ThingsCard(
          thing: item.thing!, pieces: item.pieces, title: Evidence.CardTitle(),
          designSystem: designSystem, style: isPresenting ? .cardFront : .thumbnail,
          closeAction: close, flipAction: flipCard)
      }
    )
    #if os(macOS)
      .frame(
        minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
    #endif
    .padding()
    .onAppear {
      viewModel.loadAssets(for: viewModel.assetGroups[groupIndex])
    }
  }

  private func gridColumns() -> [GridItem] {
    if adaptiveColumns {
      return [GridItem(.adaptive(minimum: 150))]
    } else {
      var baseColumns = viewModel.isLandscape ? Int(Double(columns) * 1.5) : columns
      // consider size class .regular landscape to have columns * 2
      #if os(iOS)
        if horizontalSizeClass == .regular {
          baseColumns = Int(Double(baseColumns) * 1.5)
        }
      #endif

      return Array(repeating: GridItem(.flexible()), count: max(1, baseColumns))
    }
  }
}

/// A view that displays a grid of Things cards grouped by time periods
public struct ThingsGridView: View {
  @StateObject private var viewModel: AssetsViewModel
  @StateObject private var evidenceViewModel: EvidenceViewModel

  // Logger for debugging
  private let logger = Logger(subsystem: "com.record-thing", category: "ui.things-grid")

  // Design system
  let designSystem: DesignSystemSetup

  // Callbacks
  let onThingSelected: (Things) -> Void

  @State private var columns: Int
  @State private var sidebarThing: Things?
  @State private var popupCard: Things?

  // Size class
  #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif

  // MARK: - Initialization

  public init(
    viewModel: AssetsViewModel,
    evidenceViewModel: EvidenceViewModel,
    designSystem: DesignSystemSetup = .light,
    columns: Int = 1,
    onThingSelected: @escaping (Things) -> Void
  ) {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self._evidenceViewModel = StateObject(wrappedValue: evidenceViewModel)
    self.designSystem = designSystem
    self.columns = columns
    self.onThingSelected = onThingSelected
  }

  public var thingsView: some View {
    // Main content
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24, pinnedViews: []) {
        ForEach(Array(viewModel.assetGroups.enumerated()), id: \.element.id) { index, group in
          timeSection(group: group)
          ThingsSubgridView(
            viewModel: viewModel,
            evidenceViewModel: evidenceViewModel,
            groupIndex: index,
            designSystem: designSystem,
            columns: columns,
            sidebarThing: $sidebarThing,
            popupCard: $popupCard,
            onThingSelected: onThingSelected
          )
          .frame(maxWidth: .infinity)
        }
      }
      .padding()
    }
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
        #if os(iOS)
          HStack {
            thingsView
            if let thing = sidebarThing {
              ThingDetailPanel(
                thing: thing,
                evidenceViewModel: evidenceViewModel,
                designSystem: designSystem
              ) {
                sidebarThing = nil
              }
            }
          }
        #else
          HSplitView {
            thingsView
            if let thing = sidebarThing {
              ThingDetailPanel(
                thing: thing,
                evidenceViewModel: evidenceViewModel,
                designSystem: designSystem
              ) {
                sidebarThing = nil
              }
            }
          }
        #endif
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
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
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
              let dates = try await Things.query(
                in: db, columns: [\.$created_at], matching: \.$created_at != nil)
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
      }
    }
  }

  struct ThingsGridView_Previews: PreviewProvider {
    static var previews: some View {
      @Previewable @StateObject var datasource = AppDatasource.shared
      @Previewable @StateObject var model = Model(loadedLangConst: "en")
      @Previewable @StateObject var viewModel = AssetsViewModel(db: AppDatasource.shared.db)
      @Previewable @StateObject var evidenceViewModel = EvidenceViewModel.createDefault()

      ThingsGridView(viewModel: viewModel, evidenceViewModel: evidenceViewModel, columns: 2) {
        thing in
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

  struct ThingsSubgridView_Previews: PreviewProvider {
    static var previews: some View {
      @Previewable @StateObject var datasource = AppDatasource.shared
      @Previewable @StateObject var model = Model(loadedLangConst: "en")
      @Previewable @StateObject var viewModel = AssetsViewModel.mockViewModel
      @Previewable @StateObject var evidenceViewModel = EvidenceViewModel.createDefault()

      Group {
        // Regular grid view
        VStack {
          ThingsSubgridView(
            viewModel: viewModel,
            evidenceViewModel: evidenceViewModel,
            groupIndex: 1,
            designSystem: .light,
            columns: 2,
            sidebarThing: .constant(nil),
            popupCard: .constant(nil),
            onThingSelected: { _ in }
          )
        }
        .previewDisplayName("Regular Grid")

        // With selected item
        ThingsSubgridView(
          viewModel: viewModel,
          evidenceViewModel: evidenceViewModel,
          groupIndex: 1,
          designSystem: .light,
          columns: 2,
          sidebarThing: .constant(Things.Electronics),
          popupCard: .constant(nil),
          onThingSelected: { _ in }
        )
        .previewDisplayName("With Selected Item")

        // With popup card
        ThingsSubgridView(
          viewModel: viewModel,
          evidenceViewModel: evidenceViewModel,
          groupIndex: 0,
          designSystem: .light,
          columns: 2,
          sidebarThing: .constant(nil),
          popupCard: .constant(Things.Electronics),
          onThingSelected: { _ in }
        )
        .previewDisplayName("With Popup Card")

        // Dark mode
        ThingsSubgridView(
          viewModel: viewModel,
          evidenceViewModel: evidenceViewModel,
          groupIndex: 0,
          designSystem: .dark,
          columns: 2,
          sidebarThing: .constant(nil),
          popupCard: .constant(nil),
          onThingSelected: { _ in }
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")

        // Compact layout
        ThingsSubgridView(
          viewModel: viewModel,
          evidenceViewModel: evidenceViewModel,
          groupIndex: 0,
          designSystem: .light,
          columns: 1,
          sidebarThing: .constant(nil),
          popupCard: .constant(nil),
          onThingSelected: { _ in }
        )
        .previewDisplayName("Compact Layout")
      }
      .environment(\.blackbirdDatabase, datasource.db)
      .environmentObject(model)
      .padding()
    }
  }
#endif
