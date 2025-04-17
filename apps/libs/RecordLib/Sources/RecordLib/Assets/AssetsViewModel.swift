import Foundation
import Combine
import SwiftUI
import os
import Blackbird

#if os(iOS)
import UIKit
#endif

/// Group of assets by month
public struct AssetGroup: Identifiable {
    public let id = UUID()
    public let monthYear: String
    public let month: Int
    public let year: Int
    public let assets: [Asset]
    public let from: Date
    public let to: Date
    public let title: String
    
    public init(monthYear: String, month: Int, year: Int, from: Date, to: Date, title: String) {
        self.monthYear = monthYear
        self.month = month
        self.year = year
        self.assets = []
        self.from = from
        self.to = to
        self.title = title
    }
    
    public init(monthYear: String, month: Int, year: Int, assets: [Asset]) {
        self.monthYear = monthYear
        self.month = month
        self.year = year
        self.assets = assets
        self.from = Date()
        self.to = Date()
        self.title = ""
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
    public private(set) var db: Blackbird.Database?
    
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
    
    // MARK: - Initialization
    
    public init(db: Blackbird.Database? = nil) {
        self.db = db
        self.loadDates()
        
        #if os(iOS)
        setupOrientationTracking()
        #endif
    }
    
    deinit {
        #if os(iOS)
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Loads all assets from the database and groups them by time periods
    public func loadDates() {
        guard let db = db else {
            logger.error("Database not available")
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                // Fetch all dates from things
                let dates = try await Things.query(in: db, columns: [\.$created_at], matching: \.$created_at != nil)
                logger.debug("Found \(dates.count) dates")
                
                // Convert to Date objects and sort
                let sortedDates = dates.compactMap { $0[\.$created_at] }.sorted(by: >)
                
                let sortedGroups = calcSortedGroups(sortedDates: sortedDates)
                
                await MainActor.run {
                    self.assetGroups = sortedGroups
                    self.isLoading = false
                    logger.debug("Created \(sortedGroups.count) asset groups")
                }
            } catch {
                logger.error("Failed to load dates: \(error)")
                await MainActor.run {
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
        func createDateComponents(year: Int? = nil, month: Int? = nil, day: Int? = nil) -> DateComponents {
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
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
            groups.append(AssetGroup(
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
            groups.append(AssetGroup(
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
            groups.append(AssetGroup(
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
            groups.append(AssetGroup(
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
                
                groups.append(AssetGroup(
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
                groups.append(AssetGroup(
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
    
    /*
    /// Deletes an asset
    /// - Parameter asset: The asset to delete
    public func deleteAsset(_ asset: Asset) async throws {
        guard let db = db else {
            throw NSError(domain: "AssetsViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database not available"])
        }
        
        do {
            try await db.query("""
                DELETE FROM things
                WHERE id = ?
            """, asset.id)
            
            await MainActor.run {
                // Remove from groups
                for (index, group) in assetGroups.enumerated() {
                    if let assetIndex = group.assets.firstIndex(where: { $0.id == asset.id }) {
                        var updatedGroup = group
                        updatedGroup.assets.remove(at: assetIndex)
                        assetGroups[index] = updatedGroup
                        break
                    }
                }
                
                // Clear selection if it was the selected asset
                if selectedAsset?.id == asset.id {
                    selectedAsset = nil
                }
            }
        } catch {
            logger.error("Failed to delete asset: \(error)")
            throw error
        }
    }
     */
    
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
