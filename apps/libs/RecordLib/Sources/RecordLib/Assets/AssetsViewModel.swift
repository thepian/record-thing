import Blackbird
import Combine
import Foundation
import SwiftUI
import os

#if os(iOS)
  import UIKit
#endif

/// Group of assets by month
public struct AssetGroup: Identifiable, Hashable {
  public let id = UUID()
  public let monthYear: String
  public let month: Int
  public let year: Int
  public var assets: [Asset]
  public let from: Date
  public let to: Date
  public let title: String
  public var didLoad: Bool

  public init(monthYear: String, month: Int, year: Int, from: Date, to: Date, title: String) {
    self.monthYear = monthYear
    self.month = month
    self.year = year
    self.assets = []
    self.from = from
    self.to = to
    self.title = title
    self.didLoad = false
  }

  public init(monthYear: String, month: Int, year: Int, assets: [Asset]) {
    self.monthYear = monthYear
    self.month = month
    self.year = year
    self.assets = assets
    self.from = Date()
    self.to = Date()
    self.title = ""
    self.didLoad = true
  }

  #if DEBUG
    static public let today = AssetGroup(
      monthYear: "Jan 2024", month: 1, year: 2024, from: Date(),
      to: Date().addingTimeInterval(86400), title: "Today")
    static public let year2024 = AssetGroup(
      monthYear: "2024", month: 0, year: 2024,
      from: {
        var dateComps = DateComponents()
        dateComps.calendar = Calendar.init(identifier: .gregorian)
        dateComps.day = 1
        dateComps.month = 1
        dateComps.year = 2024
        return dateComps.date!
      }(),
      to: {
        var dateComps = DateComponents()
        dateComps.calendar = Calendar.init(identifier: .gregorian)
        dateComps.day = 31
        dateComps.month = 12
        dateComps.year = 2024
        return dateComps.date!
      }(), title: "2024")
  #endif

  // MARK: - Hashable Conformance

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: AssetGroup, rhs: AssetGroup) -> Bool {
    lhs.id == rhs.id
  }
}

/// ViewModel for managing Things, Evidence, and other assets in the app
public class AssetsViewModel: ObservableObject, Observable {
  // MARK: - Properties

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.record-thing",
    category: "assets"
  )

  // Database reference
  @Published public private(set) var db: Blackbird.Database?

  // Published properties
  @Published public private(set) var assetGroups: [AssetGroup] = []
  @Published public private(set) var selectedAsset: Asset?
  @Published public private(set) var isLoading: Bool = true
  @Published public private(set) var error: Error?

  // Orientation tracking
  #if os(iOS)
    @Published public var isLandscape = false
    private var orientationObserver: NSObjectProtocol?
  #endif

  var df: DateFormatter {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd hh:mm:ss"
    return df
  }

  // MARK: - Preview Helpers

  #if DEBUG
    public static let fourThings: [Things] = [
      .Electronics,
      .Furniture,
      .Jewelry,
      .Room,
    ]

    public static let mockViewModel: AssetsViewModel = {
      let viewModel = AssetsViewModel()
      let calendar = Calendar.current
      let now = Date()

      // Today's group
      let todayStart = calendar.startOfDay(for: now)
      let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!

      // 2024 group
      let year2024Start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
      let year2024End = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

      viewModel.assetGroups = [
        AssetGroup(
          monthYear: "Today",
          month: calendar.component(.month, from: now),
          year: calendar.component(.year, from: now),
          from: todayStart,
          to: todayEnd,
          title: "Today"
        ),
        AssetGroup(
          monthYear: "2024",
          month: 1,
          year: 2024,
          from: year2024Start,
          to: year2024End,
          title: "2024"
        ),
      ]
      viewModel.isLoading = false
      return viewModel
    }()
  #endif

  // MARK: - Initialization

  public init(db: Blackbird.Database? = nil) {
    logger.info("🚀 Initializing AssetsViewModel")
    self.db = db

    if let db = db {
      logger.info("✅ Database provided to AssetsViewModel: \(String(describing: db))")
    } else {
      logger.warning("⚠️ No database provided to AssetsViewModel")
    }

    logger.info("🔄 Starting initial loadDates call")
    self.loadDates()

    #if os(iOS)
      logger.info("📱 Setting up orientation tracking")
      setupOrientationTracking()
    #endif

    logger.info("✅ AssetsViewModel initialization complete")
  }

  deinit {
    #if os(iOS)
      if let observer = orientationObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    #endif
  }

  // MARK: - Public Methods

  /// Updates the database reference and reloads data if database becomes available
  public func updateDatabase(_ newDb: Blackbird.Database?) {
    logger.info("🔄 Updating database reference")

    let hadDatabase = db != nil
    db = newDb

    if let newDb = newDb {
      logger.info("✅ Database updated successfully: \(String(describing: newDb))")

      // If we didn't have a database before, or if we have an error, reload
      if !hadDatabase || error != nil {
        logger.info("🔄 Reloading data with new database")
        loadDates()
      }
    } else {
      logger.warning("⚠️ Database set to nil")
    }
  }

  /// Loads all assets from the database and groups them by time periods
  public func loadDates() {
    logger.info("🔄 Starting loadDates")

    guard let db = db else {
      logger.error("❌ Database not available")
      error = NSError(
        domain: "AssetsViewModel", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Database not available"])
      return
    }

    logger.info("✅ Database available, starting load process")
    isLoading = true
    error = nil

    Task {
      do {
        logger.info("📊 Querying Things table for creation dates...")

        // Fetch all dates from things
        let dates = try await Things.query(
          in: db, columns: [\.$created_at], matching: \.$created_at != nil)
        logger.info("✅ Successfully queried \(dates.count) Things from database")

        // Convert to Date objects and sort
        let sortedDates = dates.compactMap { $0[\.$created_at] }.sorted(by: >)
        logger.info("📅 Extracted \(sortedDates.count) valid dates from Things")

        logger.info("🔧 Calculating sorted groups...")
        let sortedGroups = calcSortedGroups(sortedDates: sortedDates)
        logger.info("✅ Created \(sortedGroups.count) asset groups")

        await MainActor.run {
          logger.info("🎯 Updating UI with \(sortedGroups.count) groups")
          self.assetGroups = sortedGroups
          self.isLoading = false
          logger.info("✅ Asset groups loading completed successfully")

          // Automatically start loading assets for each group
          logger.info("🔄 Starting automatic asset loading for all groups")
          for group in sortedGroups {
            self.loadAssets(for: group)
          }
        }
      } catch {
        logger.error("❌ Failed to load dates: \(error)")
        logger.error("❌ Error details: \(error.localizedDescription)")

        // Log to database monitor
        DatabaseMonitor.shared.logError(
          error, context: "AssetsViewModel failed to load dates",
          query: "SELECT created_at FROM things")

        await MainActor.run {
          logger.error("🎯 Setting error state in UI")
          self.error = error
          self.isLoading = false
        }
      }
    }
  }

  func calcSortedGroups(sortedDates: [Date]) -> [AssetGroup] {
    // Create asset groups
    var groups: [AssetGroup] = []
    let calendar = Calendar.current
    let now = Date()

    // Helper function to create date components
    func createDateComponents(year: Int? = nil, month: Int? = nil, day: Int? = nil)
      -> DateComponents
    {
      var components = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute, .second], from: now)
      if let year = year { components.year = year }
      if let month = month { components.month = month }
      if let day = day { components.day = day }
      components.hour = 0
      components.minute = 0
      components.second = 0
      return components
    }

    // Helper function to check if a date range contains any dates
    func hasDatesInRange(from: Date, to: Date) -> Bool {
      return sortedDates.contains { date in
        date >= from && date < to
      }
    }

    // Today
    let todayStart = calendar.startOfDay(for: now)
    let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
    if hasDatesInRange(from: todayStart, to: todayEnd) {
      groups.append(
        AssetGroup(
          monthYear: "Today",
          month: calendar.component(.month, from: now),
          year: calendar.component(.year, from: now),
          from: todayStart,
          to: todayEnd,
          title: "Today"
        ))
    }

    // Yesterday
    let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
    if hasDatesInRange(from: yesterdayStart, to: todayStart) {
      groups.append(
        AssetGroup(
          monthYear: "Yesterday",
          month: calendar.component(.month, from: yesterdayStart),
          year: calendar.component(.year, from: yesterdayStart),
          from: yesterdayStart,
          to: todayStart,
          title: "Yesterday"
        ))
    }

    // This week (excluding yesterday & today)
    let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: todayStart)!
    if hasDatesInRange(from: thisWeekStart, to: yesterdayStart) {
      groups.append(
        AssetGroup(
          monthYear: "This Week",
          month: calendar.component(.month, from: thisWeekStart),
          year: calendar.component(.year, from: thisWeekStart),
          from: thisWeekStart,
          to: yesterdayStart,
          title: "This Week"
        ))
    }

    // This month (excluding this week)
    let thisMonthStart = calendar.date(from: createDateComponents(day: 1))!
    if hasDatesInRange(from: thisMonthStart, to: thisWeekStart) {
      groups.append(
        AssetGroup(
          monthYear: "This Month",
          month: calendar.component(.month, from: thisMonthStart),
          year: calendar.component(.year, from: thisMonthStart),
          from: thisMonthStart,
          to: thisWeekStart,
          title: "This Month"
        ))
    }

    // Previous months (past 6 months or this year)
    let currentYear = calendar.component(.year, from: now)
    let currentMonth = calendar.component(.month, from: now)

    for monthOffset in 1...6 {
      let month = currentMonth - monthOffset
      if month <= 0 {
        break
      }

      let monthStart = calendar.date(from: createDateComponents(month: month, day: 1))!
      let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

      if hasDatesInRange(from: monthStart, to: monthEnd) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: monthStart)

        groups.append(
          AssetGroup(
            monthYear: monthYear,
            month: month,
            year: currentYear,
            from: monthStart,
            to: monthEnd,
            title: monthYear
          ))
      }
    }

    // Previous years
    let years = Set(sortedDates.compactMap { calendar.component(.year, from: $0) })
    for year in years.sorted(by: >) {
      if year >= currentYear {
        continue
      }

      let yearStart = calendar.date(from: createDateComponents(year: year, month: 1, day: 1))!
      let yearEnd = calendar.date(from: createDateComponents(year: year + 1, month: 1, day: 1))!

      if hasDatesInRange(from: yearStart, to: yearEnd) {
        groups.append(
          AssetGroup(
            monthYear: "\(year)",
            month: 1,
            year: year,
            from: yearStart,
            to: yearEnd,
            title: "\(year)"
          ))
      }
    }

    // Sort groups by date range
    let sortedGroups = groups.sorted { $0.from > $1.from }
    logger.debug("Sorted groups: \(sortedGroups.count)")

    return sortedGroups
  }

  /// Selects an asset for detailed view
  /// - Parameter asset: The asset to select
  public func selectAsset(_ asset: Asset) {
    selectedAsset = asset
    logger.debug("Selected asset: \(asset.id)")
  }

  /// Clears the currently selected asset
  public func clearSelection() {
    selectedAsset = nil
  }

  /// Searches for assets matching the given query
  /// - Parameter query: The search query
  public func searchAssets(query: String) {
    // TODO: Implement search functionality
  }

  /// Filters assets by category
  /// - Parameter category: The category to filter by
  public func filterAssets(by category: AssetCategory) {
    // TODO: Implement category filtering
  }

  // Add a loading state tracker
  private var loadingGroups: Set<UUID> = []

  /// Loads assets for a specific group
  /// - Parameter group: The asset group to load assets for
  public func loadAssets(for group: AssetGroup) {
    // Skip if already loaded or loading
    guard !group.didLoad && !loadingGroups.contains(group.id) else {
      logger.debug("Skipping load for group \(group.title) - already loaded or loading")
      return
    }

    guard let db = db else {
      logger.error("Database not available")
      return
    }

    // Mark group as loading
    loadingGroups.insert(group.id)

    Task {
      do {
        // Query things within the date range
        let things = try await Things.read(
          from: db,
          matching: \.$created_at >= group.from && \.$created_at < group.to
        )

        // For each thing, load its associated evidence
        var assets: [Asset] = []
        for thing in things {
          let evidence = try await Evidence.read(
            from: db,
            matching: \.$thing_id == thing.id,
            orderBy: .ascending(\.$created_at)
          )

          // Construct pieces from evidence array
          var pieces: [EvidencePiece] = []
          for (index, evidence) in evidence.enumerated() {
            // Create metadata
            var metadata: [String: String] = [:]
            if let data = evidence.data {
              metadata["data"] = data
            }
            if let evidenceType = evidence.evidence_type {
              metadata["evidenceType"] = String(evidenceType)
            }

            // Determine the piece type based on local_file
            let type: EvidencePieceType
            if let localFile = evidence.local_file {
              let fileURL = URL(fileURLWithPath: localFile)
              let fileExtension = fileURL.pathExtension.lowercased()

              switch fileExtension {
              case "mp4", "mov", "m4v":
                // Video files
                type = .video(fileURL)
                metadata["fileType"] = "video"

              case "jpg", "jpeg", "png", "heic":
                // Image files
                if let image = loadImage(from: fileURL) {
                  type = .custom(image)
                  metadata["fileType"] = "image"
                } else {
                  type = .system("photo")
                  metadata["fileType"] = "image"
                  metadata["error"] = "Failed to load image"
                }

              case "pdf", "doc", "docx":
                // Document files
                type = .system("doc.text")
                metadata["fileType"] = "document"

              default:
                // Unknown file type
                type = .system("questionmark.circle")
                metadata["fileType"] = "unknown"
              }

              metadata["fileExtension"] = fileExtension
              metadata["filePath"] = localFile
            } else {
              // Default to generic photo
              type = .system("photo")
              metadata["fileType"] = "system"
            }

            // Create the evidence piece
            let piece = EvidencePiece(
              index: index,
              title: evidence.name,
              type: type,
              metadata: metadata,
              timestamp: evidence.created_at,
              color: .accentColor
            )
            pieces.append(piece)
          }

          // Create an Asset instance for each Thing with its Evidence
          let asset = Asset(
            id: thing.id,
            name: thing.title ?? "Untitled",
            category: .other,
            createdAt: thing.created_at ?? Date(),
            tags: thing.tagsArray,
            thing: thing,
            evidence: evidence,
            pieces: pieces,
            thumbnailName: thing.evidence_type_name
          )
          assets.append(asset)
        }
        let assetsCount = assets.count

        await MainActor.run {
          // Update the group in assetGroups
          if let index = self.assetGroups.firstIndex(where: { $0.id == group.id }) {
            var updatedGroup = self.assetGroups[index]
            updatedGroup.assets = assets
            updatedGroup.didLoad = true
            self.assetGroups[index] = updatedGroup
          }

          // Remove from loading set
          self.loadingGroups.remove(group.id)

          logger.debug(
            "Loaded \(things.count) things with \(assetsCount) assets for group \(group.title)")
        }
      } catch {
        logger.error("Failed to load assets: \(error)")
        await MainActor.run {
          self.loadingGroups.remove(group.id)
          logger.debug("removed.")
        }
      }
    }
  }

  // Helper function to load images from file system
  private func loadImage(from url: URL) -> Image? {
    #if os(iOS)
      if let uiImage = UIImage(contentsOfFile: url.path) {
        return Image(uiImage: uiImage)
      }
    #elseif os(macOS)
      if let nsImage = NSImage(contentsOfFile: url.path) {
        return Image(nsImage: nsImage)
      }
    #endif
    return nil
  }

  // MARK: - Orientation Tracking

  #if os(iOS)
    private func setupOrientationTracking() {
      // Start device orientation monitoring
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()

      // Observe orientation changes
      orientationObserver = NotificationCenter.default.addObserver(
        forName: UIDevice.orientationDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.updateOrientation()
      }

      // Set initial orientation
      updateOrientation()
    }

    private func updateOrientation() {
      let orientation = UIDevice.current.orientation
      let newIsLandscape = orientation == .landscapeLeft || orientation == .landscapeRight

      if isLandscape != newIsLandscape {
        isLandscape = newIsLandscape
        logger.debug("Orientation changed to \(newIsLandscape ? "landscape" : "portrait")")
      }
    }
  #endif

  /// Updates the assets for a specific group
  /// - Parameters:
  ///   - groupId: The ID of the group to update
  ///   - assets: The new assets to set
  public func updateGroupAssets(groupId: UUID, assets: [Asset]) {
    if let index = assetGroups.firstIndex(where: { $0.id == groupId }) {
      var updatedGroup = assetGroups[index]
      updatedGroup.assets = assets
      assetGroups[index] = updatedGroup
      logger.debug("Updated assets for group \(updatedGroup.title)")
    }
  }
}

public struct AssetsViewModelKey: EnvironmentKey {
  static public let defaultValue: AssetsViewModel? = nil
}

extension EnvironmentValues {
  public var assetsViewModel: AssetsViewModel? {
    get { self[AssetsViewModel.self] }
    set { self[AssetsViewModel.self] = newValue }
  }
}
