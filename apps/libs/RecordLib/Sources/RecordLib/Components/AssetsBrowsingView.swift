import SwiftUI
import os

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A view for browsing and managing luxury assets captured by the app
public struct AssetsBrowsingView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui")
    
    // State
    @State private var selectedTab: AssetTab = .unfinished
    @State private var searchText: String = ""
    @State private var selectedAsset: Asset? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    // Data
    private let assetGroups: [AssetGroup]
    private let onAssetSelected: ((Asset) -> Void)?
    private let onRecordTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new AssetsBrowsingView
    /// - Parameters:
    ///   - assetGroups: The asset groups to display, organized by month
    ///   - onAssetSelected: Action to perform when an asset is selected
    ///   - onRecordTapped: Action to perform when the record button is tapped
    public init(
        assetGroups: [AssetGroup] = [],
        onAssetSelected: ((Asset) -> Void)? = nil,
        onRecordTapped: (() -> Void)? = nil
    ) {
        self.assetGroups = assetGroups
        self.onAssetSelected = onAssetSelected
        self.onRecordTapped = onRecordTapped
        
        logger.debug("AssetsBrowsingView initialized with \(assetGroups.count) groups")
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 700 {
                // iPad/Mac layout with sidebar
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    // Overview sidebar
                    overviewContent
                        .navigationTitle("Assets")
                        #if os(macOS)
                        .toolbar {
                            ToolbarItem {
                                recordButton
                            }
                        }
                        #else
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                recordButton
                            }
                        }
                        #endif
                } detail: {
                    // Detail view
                    if let asset = selectedAsset {
                        assetDetailView(asset)
                    } else {
                        Text("Select an asset to view details")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                // iPhone full-screen layout
                NavigationStack {
                    overviewContent
                        .navigationTitle("Assets")
                        #if os(macOS)
                        .toolbar {
                            ToolbarItem {
                                recordButton
                            }
                        }
                        #else
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                recordButton
                            }
                        }
                        #endif
                        .navigationDestination(for: Asset.self) { asset in
                            assetDetailView(asset)
                        }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            logger.debug("AssetsBrowsingView appeared")
        }
    }
    
    // MARK: - UI Components
    
    /// The main overview content
    private var overviewContent: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Asset groups
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(assetGroups) { group in
                            assetGroupSection(group)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .foregroundColor(.white)
    }
    
    /// Record button
    private var recordButton: some View {
        Button(action: {
            onRecordTapped?()
            logger.debug("Record button tapped")
        }) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(Color(white: 0.2)))
        }
        #if os(macOS)
        .buttonStyle(BorderlessButtonStyle())
        #else
        .buttonStyle(PlainButtonStyle())
        #endif
    }
    
    /// Tab selector at the top
    private var tabSelector: some View {
        HStack(spacing: 16) {
            tabButton(.unfinished)
            tabButton(.timeline)
            tabButton(.shared)
            
            Spacer()
            
            recordButton
        }
    }
    
    /// Individual tab button
    private func tabButton(_ tab: AssetTab) -> some View {
        Button(action: {
            selectedTab = tab
            logger.debug("Tab selected: \(tab.rawValue)")
        }) {
            Text(tab.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(selectedTab == tab ? Color(white: 0.2) : Color.clear)
                )
        }
        #if os(macOS)
        .buttonStyle(BorderlessButtonStyle())
        #else
        .buttonStyle(PlainButtonStyle())
        #endif
    }
    
    /// Section for a group of assets by month
    private func assetGroupSection(_ group: AssetGroup) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month header
            Text(group.monthYear)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            // Grid of assets, 3 per row
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(group.assets) { asset in
                    assetGridItem(asset)
                }
            }
        }
    }
    
    /// Grid item for a single asset
    private func assetGridItem(_ asset: Asset) -> some View {
        Button(action: {
            handleAssetSelection(asset)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Asset image
                ZStack {
                    if let thumbnailName = asset.thumbnailName {
                        Image(thumbnailName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.15))
                            .frame(height: 120)
                        
                        Image(systemName: asset.category.iconName)
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 120)
                
                // Asset name
                Text(asset.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Asset category
                Text(asset.category.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.6))
                    .lineLimit(1)
            }
        }
        #if os(macOS)
        .buttonStyle(BorderlessButtonStyle())
        #else
        .buttonStyle(PlainButtonStyle())
        #endif
    }
    
    /// Detail view for a selected asset
    private func assetDetailView(_ asset: Asset) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero image
                ZStack {
                    if let thumbnailName = asset.thumbnailName {
                        Image(thumbnailName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(16)
                    } else {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .aspectRatio(4/3, contentMode: .fit)
                            .cornerRadius(16)
                            .overlay(
                                Image(systemName: asset.category.iconName)
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // Asset info
                VStack(alignment: .leading, spacing: 12) {
                    // Title and category
                    Text(asset.name)
                        .font(.system(size: 28, weight: .bold))
                    
                    Text(asset.category.displayName)
                        .font(.system(size: 18))
                        .foregroundColor(Color(white: 0.7))
                    
                    Divider()
                        .background(Color(white: 0.3))
                        .padding(.vertical, 8)
                    
                    // Date
                    HStack {
                        Text("Date Captured:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(white: 0.7))
                        
                        Spacer()
                        
                        Text(asset.formattedDate)
                            .font(.system(size: 16))
                    }
                    
                    // Tags
                    if !asset.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(white: 0.7))
                            
                            FlowLayout(spacing: 8) {
                                ForEach(asset.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(white: 0.2))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(asset.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(Color.black)
    }
    
    // MARK: - Helper Methods
    
    /// Handle asset selection based on device type
    private func handleAssetSelection(_ asset: Asset) {
        logger.debug("Asset selected: \(asset.id)")
        
        // Update selected asset for iPad layout
        selectedAsset = asset
        
        // Call the selection handler
        onAssetSelected?(asset)
    }
}

// MARK: - Supporting Types

/// Tab options for the assets view
public enum AssetTab: String, CaseIterable {
    case unfinished
    case timeline
    case shared
    
    var displayName: String {
        switch self {
        case .unfinished: return "Unfinished"
        case .timeline: return "Timeline"
        case .shared: return "Shared"
        }
    }
}

/// Group of assets by month
public struct AssetGroup: Identifiable {
    public let id = UUID()
    public let monthYear: String
    public let month: Int
    public let year: Int
    public let assets: [Asset]
    
    public init(monthYear: String, month: Int, year: Int, assets: [Asset]) {
        self.monthYear = monthYear
        self.month = month
        self.year = year
        self.assets = assets
    }
}

/// Model representing a luxury asset
public struct Asset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: AssetCategory
    public let createdAt: Date
    public let tags: [String]
    public let thumbnailName: String?
    
    public init(
        id: String,
        name: String,
        category: AssetCategory,
        createdAt: Date,
        tags: [String] = [],
        thumbnailName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.createdAt = createdAt
        self.tags = tags
        self.thumbnailName = thumbnailName
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
}

/// Categories for luxury assets
public enum AssetCategory: String, CaseIterable {
    case watches
    case bags
    case shoes
    case accessories
    case jewelry
    case clothing
    case other
    
    /// Display name for the category
    var displayName: String {
        switch self {
        case .watches: return "Watches"
        case .bags: return "Bags"
        case .shoes: return "Shoes"
        case .accessories: return "Accessories"
        case .jewelry: return "Jewelry"
        case .clothing: return "Clothing"
        case .other: return "Other"
        }
    }
    
    /// Icon name for the category
    var iconName: String {
        switch self {
        case .watches: return "clock.fill"
        case .bags: return "bag.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return "eyeglasses"
        case .jewelry: return "sparkles"
        case .clothing: return "tshirt.fill"
        case .other: return "square.fill"
        }
    }
}

/// Flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                // Move to next row
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        
        height = y + maxHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                // Move to next row
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Preview
struct AssetsBrowsingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // iPhone preview
            AssetsBrowsingView(
                assetGroups: sampleAssetGroups,
                onAssetSelected: { asset in
                    print("Selected asset: \(asset.name)")
                },
                onRecordTapped: {
                    print("Record tapped")
                }
            )
            .previewDisplayName("iPhone")
            
            // iPad preview
            AssetsBrowsingView(
                assetGroups: sampleAssetGroups,
                onAssetSelected: { asset in
                    print("Selected asset: \(asset.name)")
                },
                onRecordTapped: {
                    print("Record tapped")
                }
            )
            .previewDevice("iPad Pro (11-inch)")
            .previewDisplayName("iPad")
        }
    }
    
    // Sample data for previews
    static var sampleAssetGroups: [AssetGroup] {
        [
            AssetGroup(
                monthYear: "March 2025",
                month: 3,
                year: 2025,
                assets: [
                    Asset(
                        id: "1",
                        name: "Rolex Daytona",
                        category: .watches,
                        createdAt: Date(),
                        tags: ["luxury", "watch", "gold"],
                        thumbnailName: nil
                    ),
                    Asset(
                        id: "2",
                        name: "LV Neverfull",
                        category: .bags,
                        createdAt: Date(),
                        tags: ["luxury", "bag", "leather"],
                        thumbnailName: nil
                    ),
                    Asset(
                        id: "3",
                        name: "Louboutin Pumps",
                        category: .shoes,
                        createdAt: Date(),
                        tags: ["luxury", "shoes", "red"],
                        thumbnailName: nil
                    )
                ]
            ),
            AssetGroup(
                monthYear: "February 2025",
                month: 2,
                year: 2025,
                assets: [
                    Asset(
                        id: "4",
                        name: "Gucci Sunglasses",
                        category: .accessories,
                        createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
                        tags: ["luxury", "sunglasses", "summer"],
                        thumbnailName: nil
                    ),
                    Asset(
                        id: "5",
                        name: "Hermès Wallet",
                        category: .accessories,
                        createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
                        tags: ["luxury", "wallet", "leather"],
                        thumbnailName: nil
                    ),
                    Asset(
                        id: "6",
                        name: "Cartier Love",
                        category: .jewelry,
                        createdAt: Date().addingTimeInterval(-2592000), // 30 days ago
                        tags: ["luxury", "bracelet", "gold"],
                        thumbnailName: nil
                    )
                ]
            )
        ]
    }
} 