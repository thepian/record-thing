//
//  BrowseNavigationView.swift
//  RecordLib
//
//  Created by Cline on 10.03.2025.
//

import os
import SwiftUI
import Blackbird

// Tab enum for selection
public enum BrowseNavigationTab: String, Codable, CaseIterable {
    // Buttons in App Toolbar
    case record
    case assets
    case actions

    // Data Browsing tabs
    case things
    case types
    case feed
    case favorites
    
    var icon: String {
        switch self {
        case .record: return "camera"
        case .assets: return "photo.stack"
        case .actions: return "bolt"
        case .things: return "list.bullet"
        case .types: return "heart.fill"
        case .feed: return "tray"
        case .favorites: return "star"
        }
    }
    
    var title: String {
        switch self {
        case .record: return "Record"
        case .assets: return "Assets"
        case .actions: return "Actions"
        case .things: return "Things"
        case .types: return "Types"
        case .feed: return "Feed"
        case .favorites: return "Favorites"
        }
    }
}

/// Navigation destination model for the app
public struct BrowseDestination: Hashable, Identifiable, Codable {
    public var id: UUID = UUID()
    public var tab: BrowseNavigationTab
    public var recordType: String
    public var recordId: String?
    public var additionalContext: [String: String]?
    
    public init(tab: BrowseNavigationTab, recordType: String, recordId: String? = nil, additionalContext: [String: String]? = nil) {
        self.tab = tab
        self.recordType = recordType
        self.recordId = recordId
        self.additionalContext = additionalContext
    }
    
    // Helper to create a destination for a specific tab with default record type
    public static func forTab(_ tab: BrowseNavigationTab) -> BrowseDestination {
        let defaultRecordType: String
        switch tab {
        case .things: defaultRecordType = "thing"
        case .types: defaultRecordType = "type"
        case .feed: defaultRecordType = "feed"
        case .favorites: defaultRecordType = "favorite"
        default: defaultRecordType = "unknown"
        }
        return BrowseDestination(tab: tab, recordType: defaultRecordType)
    }
}

/// A modern navigation component for browsing app content using NavigationStack and NavigationSplitView
public struct BrowseNavigationView<ThingsContent: View, TypesContent: View, FeedContent: View, FavoritesContent: View>: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "BrowseNavigationView")
    
    // State
    @Binding private var selectedTab: BrowseNavigationTab
    @State private var previousTab: BrowseNavigationTab
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    // Navigation state
    @Binding private var navigationPath: NavigationPath
    
    // Content views
    private let thingsContent: ThingsContent
    private let typesContent: TypesContent
    private let feedContent: FeedContent
    private let favoritesContent: FavoritesContent
    
    // Configuration
    private let useSlideTransition: Bool
    private let showToolbar: Bool
    private let onRecordTapped: (() -> Void)?
    
    /// Creates a new BrowseNavigationView
    /// - Parameters:
    ///   - selectedTab: Binding to the selected tab
    ///   - navigationPath: Binding to the navigation path
    ///   - useSlideTransition: Whether to use slide transitions between tabs
    ///   - showToolbar: Whether to show the toolbar
    ///   - onRecordTapped: Action to perform when the record button is tapped
    ///   - thingsContent: Content for the Things tab
    ///   - typesContent: Content for the Types tab
    ///   - feedContent: Content for the Feed tab
    ///   - favoritesContent: Content for the Favorites tab
    public init(
        selectedTab: Binding<BrowseNavigationTab>,
        navigationPath: Binding<NavigationPath>,
        useSlideTransition: Bool = true,
        showToolbar: Bool = true,
        onRecordTapped: (() -> Void)? = nil,
        @ViewBuilder thingsContent: () -> ThingsContent,
        @ViewBuilder typesContent: () -> TypesContent,
        @ViewBuilder feedContent: () -> FeedContent,
        @ViewBuilder favoritesContent: () -> FavoritesContent
    ) {
        self._selectedTab = selectedTab
        self._previousTab = State(initialValue: selectedTab.wrappedValue)
        self._navigationPath = navigationPath
        self.useSlideTransition = useSlideTransition
        self.showToolbar = showToolbar
        self.onRecordTapped = onRecordTapped
        self.thingsContent = thingsContent()
        self.typesContent = typesContent()
        self.feedContent = feedContent()
        self.favoritesContent = favoritesContent()
        
        logger.debug("BrowseNavigationView initialized with selected tab: \(selectedTab.wrappedValue.rawValue)")
    }
    
    /// Creates a new BrowseNavigationView without navigation path (for backward compatibility)
    /// - Parameters:
    ///   - selectedTab: Binding to the selected tab
    ///   - useSlideTransition: Whether to use slide transitions between tabs
    ///   - showToolbar: Whether to show the toolbar
    ///   - onRecordTapped: Action to perform when the record button is tapped
    ///   - thingsContent: Content for the Things tab
    ///   - typesContent: Content for the Types tab
    ///   - feedContent: Content for the Feed tab
    ///   - favoritesContent: Content for the Favorites tab
    public init(
        selectedTab: Binding<BrowseNavigationTab>,
        useSlideTransition: Bool = true,
        showToolbar: Bool = true,
        onRecordTapped: (() -> Void)? = nil,
        @ViewBuilder thingsContent: () -> ThingsContent,
        @ViewBuilder typesContent: () -> TypesContent,
        @ViewBuilder feedContent: () -> FeedContent,
        @ViewBuilder favoritesContent: () -> FavoritesContent
    ) {
        self.init(
            selectedTab: selectedTab,
            navigationPath: .constant(NavigationPath()),
            useSlideTransition: useSlideTransition,
            showToolbar: showToolbar,
            onRecordTapped: onRecordTapped,
            thingsContent: thingsContent,
            typesContent: typesContent,
            feedContent: feedContent,
            favoritesContent: favoritesContent
        )
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > 700 {
                // Use NavigationSplitView for larger screens (iPad, Mac)
                splitViewLayout
            } else {
                // Use TabView with NavigationStack for smaller screens (iPhone)
                tabViewLayout
            }
        }
        .onChange(of: selectedTab) { newValue in
            logger.debug("Tab changed to: \(newValue.rawValue)")
            
            // Update previous tab after animation completes if using slide transition
            if useSlideTransition {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    previousTab = newValue
                }
            }
        }
    }
    
    // MARK: - Layouts
    
    /// Split view layout for larger screens
    private var splitViewLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar with tab options
            List(BrowseNavigationTab.allCases.filter { $0 != .record && $0 != .assets && $0 != .actions }, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.title, systemImage: tab.icon)
                }
                .buttonStyle(.plain)
                .foregroundColor(selectedTab == tab ? .accentColor : .primary)
            }
            .navigationTitle("Browse")
            .toolbar {
                #if os(macOS)
                ToolbarItem {
                    RecordButtonToolbarItem(
                        showToolbar: showToolbar,
                        onRecordTapped: onRecordTapped
                    )
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    RecordButtonToolbarItem(
                        showToolbar: showToolbar,
                        onRecordTapped: onRecordTapped
                    )
                }
                #endif
            }
        } detail: {
            // Detail view based on selected tab
            Group {
                switch selectedTab {
                case .things:
                    NavigationStack(path: $navigationPath) {
                        thingsContent
                            .navigationTitle("Things")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                case .types:
                    NavigationStack(path: $navigationPath) {
                        typesContent
                            .navigationTitle("Types")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                case .feed:
                    NavigationStack(path: $navigationPath) {
                        feedContent
                            .navigationTitle("Feed")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                case .favorites:
                    NavigationStack(path: $navigationPath) {
                        favoritesContent
                            .navigationTitle("Favorites")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                default:
                    Text("Select a category")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Tab view layout for smaller screens
    private var tabViewLayout: some View {
        ZStack(alignment: .bottom) {
            if useSlideTransition {
                // Custom tab view with slide transitions
                tabContentWithSlideTransition
            } else {
                // Standard SwiftUI TabView
                TabView(selection: $selectedTab) {
                    NavigationStack(path: $navigationPath) {
                        thingsContent
                            .navigationTitle("Things")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                    .tabItem {
                        Label("Things", systemImage: "list.bullet")
                    }
                    .tag(BrowseNavigationTab.things)
                    
                    NavigationStack(path: $navigationPath) {
                        typesContent
                            .navigationTitle("Types")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                    .tabItem {
                        Label("Types", systemImage: "heart.fill")
                    }
                    .tag(BrowseNavigationTab.types)
                    
                    NavigationStack(path: $navigationPath) {
                        feedContent
                            .navigationTitle("Feed")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                    .tabItem {
                        Label("Feed", systemImage: "tray")
                    }
                    .tag(BrowseNavigationTab.feed)
                    
                    NavigationStack(path: $navigationPath) {
                        favoritesContent
                            .navigationTitle("Favorites")
                            .toolbar {
                                #if os(macOS)
                                ToolbarItem {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #else
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    RecordButtonToolbarItem(
                                        showToolbar: showToolbar,
                                        onRecordTapped: onRecordTapped
                                    )
                                }
                                #endif
                            }
                    }
                    .tabItem {
                        Label("Favorites", systemImage: "star")
                    }
                    .tag(BrowseNavigationTab.favorites)
                }
            }
            
            // Optional floating toolbar
            if showToolbar && useSlideTransition {
                FloatingTabBar(
                    selectedTab: Binding(
                        get: { tabToIndex(selectedTab) },
                        set: { selectedTab = indexToTab($0) }
                    ),
                    tabs: [
                        FloatingTabBar.TabItem(icon: "list.bullet", title: "Things"),
                        FloatingTabBar.TabItem(icon: "heart.fill", title: "Types"),
                        FloatingTabBar.TabItem(icon: "tray", title: "Feed"),
                        FloatingTabBar.TabItem(icon: "star", title: "Favorites")
                    ]
                )
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Slide Transition Implementation
    
    /// Tab content with slide transitions
    private var tabContentWithSlideTransition: some View {
        GeometryReader { geometry in
            ZStack {
                // Things tab
                NavigationStack(path: $navigationPath) {
                    thingsContent
                        .navigationTitle("Things")
                        .toolbar {
                            #if os(macOS)
                            ToolbarItem {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #else
                            ToolbarItem(placement: .navigationBarTrailing) {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #endif
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: offsetForTab(.things, geometry: geometry))
                
                // Types tab
                NavigationStack(path: $navigationPath) {
                    typesContent
                        .navigationTitle("Types")
                        .toolbar {
                            #if os(macOS)
                            ToolbarItem {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #else
                            ToolbarItem(placement: .navigationBarTrailing) {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #endif
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: offsetForTab(.types, geometry: geometry))
                
                // Feed tab
                NavigationStack(path: $navigationPath) {
                    feedContent
                        .navigationTitle("Feed")
                        .toolbar {
                            #if os(macOS)
                            ToolbarItem {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #else
                            ToolbarItem(placement: .navigationBarTrailing) {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #endif
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: offsetForTab(.feed, geometry: geometry))
                
                // Favorites tab
                NavigationStack(path: $navigationPath) {
                    favoritesContent
                        .navigationTitle("Favorites")
                        .toolbar {
                            #if os(macOS)
                            ToolbarItem {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #else
                            ToolbarItem(placement: .navigationBarTrailing) {
                                RecordButtonToolbarItem(
                                    showToolbar: showToolbar,
                                    onRecordTapped: onRecordTapped
                                )
                            }
                            #endif
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: offsetForTab(.favorites, geometry: geometry))
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the offset for a tab based on the selected tab
    private func offsetForTab(_ tab: BrowseNavigationTab, geometry: GeometryProxy) -> CGFloat {
        let currentIndex = tabToIndex(selectedTab)
        let tabIndex = tabToIndex(tab)
        
        return CGFloat(tabIndex - currentIndex) * geometry.size.width
    }
    
    /// Convert a tab to its index
    private func tabToIndex(_ tab: BrowseNavigationTab) -> Int {
        switch tab {
        case .things: return 0
        case .types: return 1
        case .feed: return 2
        case .favorites: return 3
        default: return 0
        }
    }
    
    /// Convert an index to its corresponding tab
    private func indexToTab(_ index: Int) -> BrowseNavigationTab {
        switch index {
        case 0: return .things
        case 1: return .types
        case 2: return .feed
        case 3: return .favorites
        default: return .things
        }
    }
}

// MARK: - Reusable Components

/// A reusable toolbar item for the record/camera button
public struct RecordButtonToolbarItem: View {
    private let logger = Logger(subsystem: "com.record-thing", category: "ui")
    
    // Action to perform when the button is tapped
    let onRecordTapped: (() -> Void)?
    
    // Configuration
    let showToolbar: Bool
    
    // Optional customization properties
    let iconName: String
    let iconColor: Color?
    
    /// Creates a new RecordButtonToolbarItem
    /// - Parameters:
    ///   - showToolbar: Whether to show the toolbar button (if false, returns an empty toolbar item)
    ///   - onRecordTapped: Action to perform when the button is tapped
    ///   - iconName: Name of the system image to use (defaults to "camera")
    ///   - iconColor: Color of the icon (defaults to nil, which uses the system accent color)
    public init(
        showToolbar: Bool = true,
        onRecordTapped: (() -> Void)? = nil,
        iconName: String = "camera",
        iconColor: Color? = nil
    ) {
        self.showToolbar = showToolbar
        self.onRecordTapped = onRecordTapped
        self.iconName = iconName
        self.iconColor = iconColor
    }
    
    public var body: some View {
        if showToolbar {
            Button {
                // Log the button tap with detailed information
                logger.debug("Record button tapped (icon: \(iconName), hasAction: \(onRecordTapped != nil))")
                
                // Call the action if provided
                onRecordTapped?()
            } label: {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
            }
            .disabled(onRecordTapped == nil)
            // Add accessibility label
            .accessibilityLabel("Record")
            .onAppear {
                // Log when the button appears
                logger.debug("Record button appeared (icon: \(iconName), enabled: \(onRecordTapped != nil))")
            }
        } else {
            // Return empty view when toolbar should not be shown
            EmptyView()
                .onAppear {
                    // Log when the button is hidden
                    logger.debug("Record button hidden (showToolbar: false)")
                }
        }
    }
}

// MARK: - Preview
struct BrowseNavigationView_Previews: PreviewProvider {
    // Preview models
    struct Thing: Identifiable, Hashable {
        let id: String
        let name: String
        let category: String
        let imageSystemName: String
    }
    
    struct ProductType: Identifiable, Hashable {
        let id: String
        let name: String
        let count: Int
        let imageSystemName: String
    }
    
    // Sample data
    static let sampleThings: [Thing] = [
        Thing(id: "1", name: "Coffee Maker", category: "kitchen", imageSystemName: "cup.and.saucer"),
        Thing(id: "2", name: "Laptop", category: "electronics", imageSystemName: "laptopcomputer"),
        Thing(id: "3", name: "Running Shoes", category: "clothing", imageSystemName: "shoe"),
        Thing(id: "4", name: "Headphones", category: "electronics", imageSystemName: "headphones"),
        Thing(id: "5", name: "Water Bottle", category: "kitchen", imageSystemName: "drop")
    ]
    
    static let sampleTypes: [ProductType] = [
        ProductType(id: "1", name: "Electronics", count: 42, imageSystemName: "desktopcomputer"),
        ProductType(id: "2", name: "Kitchen", count: 28, imageSystemName: "fork.knife"),
        ProductType(id: "3", name: "Clothing", count: 35, imageSystemName: "tshirt"),
        ProductType(id: "4", name: "Sports", count: 19, imageSystemName: "figure.run"),
        ProductType(id: "5", name: "Books", count: 53, imageSystemName: "book")
    ]
    
    // Enhanced preview views
    struct ThingsView: View {
        var body: some View {
            List {
                Section(header: Text("Recently Added")) {
                    ForEach(sampleThings) { thing in
                        NavigationLink(value: BrowseDestination(
                            tab: .things,
                            recordType: "thing",
                            recordId: thing.id
                        )) {
                            HStack {
                                Image(systemName: thing.imageSystemName)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(thing.name)
                                        .font(.headline)
                                    Text(thing.category.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Categories")) {
                    NavigationLink("Kitchen Items", value: BrowseDestination(
                        tab: .things,
                        recordType: "category",
                        recordId: "kitchen"
                    ))
                    
                    NavigationLink("Electronics", value: BrowseDestination(
                        tab: .things,
                        recordType: "category",
                        recordId: "electronics"
                    ))
                    
                    NavigationLink("Clothing", value: BrowseDestination(
                        tab: .things,
                        recordType: "category",
                        recordId: "clothing"
                    ))
                }
            }
            .navigationDestination(for: BrowseDestination.self, destination: {
                dest in
                DetailView(destination: dest)
            })
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #endif
        }
    }
    
    struct TypesView: View {
        var body: some View {
            List {
                Section(header: Text("Popular Types")) {
                    ForEach(sampleTypes) { type in
                        NavigationLink(value: BrowseDestination(
                            tab: .types,
                            recordType: "productType",
                            recordId: type.id
                        )) {
                            HStack {
                                Image(systemName: type.imageSystemName)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(type.name)
                                        .font(.headline)
                                    Text("\(type.count) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Browse By")) {
                    NavigationLink("Brands", value: BrowseDestination(
                        tab: .types,
                        recordType: "browseBy",
                        recordId: "brands"
                    ))
                    
                    NavigationLink("Price Range", value: BrowseDestination(
                        tab: .types,
                        recordType: "browseBy",
                        recordId: "priceRange"
                    ))
                    
                    NavigationLink("Ratings", value: BrowseDestination(
                        tab: .types,
                        recordType: "browseBy",
                        recordId: "ratings"
                    ))
                }
            }
#if os(iOS)
            .listStyle(InsetGroupedListStyle())
#endif
            .navigationDestination(for: BrowseDestination.self, destination: {
                destination in
                DetailView(destination: destination)
            })
        }
    }
    
    struct FeedView: View {
        var body: some View {
            List(1...10, id: \.self) { item in
                NavigationLink("Feed Item \(item)", value: BrowseDestination(
                    tab: .feed,
                    recordType: "feed",
                    recordId: "\(item)"
                ))
            }
            .navigationDestination(for: BrowseDestination.self, destination: {
                destination in
                DetailView(destination: destination)
            })
        }
    }
    
    struct FavoritesView: View {
        var body: some View {
            List(1...5, id: \.self) { item in
                NavigationLink("Favorite \(item)", value: BrowseDestination(
                    tab: .favorites,
                    recordType: "favorite",
                    recordId: "\(item)"
                ))
            }
            .navigationDestination(for: BrowseDestination.self, destination: {
                destination in
                DetailView(destination: destination)
            })
        }
    }
    
    // Detail views for different record types
    struct ThingDetailView: View {
        let thing: Thing
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: thing.imageSystemName)
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading) {
                            Text(thing.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(thing.category.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        HStack {
                            Text("ID:")
                                .fontWeight(.medium)
                            Text(thing.id)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Category:")
                                .fontWeight(.medium)
                            Text(thing.category.capitalized)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Added:")
                                .fontWeight(.medium)
                            Text("March 15, 2025")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Related items section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Related Items")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(sampleThings.filter { $0.id != thing.id && $0.category == thing.category }) { relatedThing in
                                    NavigationLink(value: BrowseDestination(
                                        tab: .things,
                                        recordType: "thing",
                                        recordId: relatedThing.id
                                    )) {
                                        VStack {
                                            Image(systemName: relatedThing.imageSystemName)
                                                .font(.system(size: 30))
                                                .foregroundColor(.accentColor)
                                                .frame(width: 60, height: 60)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                            
                                            Text(relatedThing.name)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(width: 80)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(thing.name)
        }
    }
    
    struct CategoryDetailView: View {
        let categoryId: String
        
        var categoryName: String {
            categoryId.capitalized
        }
        
        var filteredThings: [Thing] {
            sampleThings.filter { $0.category == categoryId }
        }
        
        var body: some View {
            List {
                Section(header: Text("\(categoryName) Items")) {
                    ForEach(filteredThings) { thing in
                        NavigationLink(value: BrowseDestination(
                            tab: .things,
                            recordType: "thing",
                            recordId: thing.id
                        )) {
                            HStack {
                                Image(systemName: thing.imageSystemName)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 30, height: 30)
                                
                                Text(thing.name)
                                    .font(.headline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if filteredThings.isEmpty {
                    Section {
                        Text("No items found in this category")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .navigationTitle(categoryName)
        }
    }
    
    struct ProductTypeDetailView: View {
        let productType: ProductType
        
        var body: some View {
            VStack(spacing: 0) {
                // Header
                VStack {
                    Image(systemName: productType.imageSystemName)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .padding(.top)
                    
                    Text(productType.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                    
                    Text("\(productType.count) items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                
                // Stats
                HStack(spacing: 0) {
                    Spacer()
                    
                    VStack {
                        Text("42%")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Growth")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    VStack {
                        Text("4.8")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Avg Rating")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    VStack {
                        Text("12")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Brands")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                .padding(.vertical)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Popular items
                List {
                    Section(header: Text("Popular Items")) {
                        ForEach(1...5, id: \.self) { i in
                            HStack {
                                Text("Popular \(productType.name) Item \(i)")
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("4.\(i)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Top Brands")) {
                        ForEach(1...3, id: \.self) { i in
                            HStack {
                                Text("Brand \(i)")
                                Spacer()
                                Text("\(i * 5) products")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(productType.name)
        }
    }
    
    struct DetailView: View {
        let destination: BrowseDestination
        
        var body: some View {
            Group {
                if destination.recordType == "thing", let thingId = destination.recordId, let thing = sampleThings.first(where: { $0.id == thingId }) {
                    ThingDetailView(thing: thing)
                }
                else if destination.recordType == "category", let categoryId = destination.recordId {
                    CategoryDetailView(categoryId: categoryId)
                }
                else if destination.recordType == "productType", let typeId = destination.recordId, let productType = sampleTypes.first(where: { $0.id == typeId }) {
                    ProductTypeDetailView(productType: productType)
                }
                else {
                    // Fallback for other record types
                    VStack {
                        Text("Tab: \(destination.tab.title)")
                            .font(.headline)
                        
                        Text("Record Type: \(destination.recordType)")
                            .font(.subheadline)
                        
                        if let recordId = destination.recordId {
                            Text("Record ID: \(recordId)")
                                .font(.subheadline)
                        }
                        
                        Spacer().frame(height: 20)
                        
                        NavigationLink("Go deeper", value: BrowseDestination(
                            tab: destination.tab,
                            recordType: destination.recordType,
                            recordId: destination.recordId,
                            additionalContext: ["level": "deeper"]
                        ))
                    }
                    .padding()
                }
            }
        }
    }
    
    static var previews: some View {
        PreviewContainer()
    }
    
    struct PreviewContainer: View {
        @State private var selectedTab: BrowseNavigationTab = .things
        @State private var navigationPath = NavigationPath()
        
        var body: some View {
            VStack {
                // Tab switcher for testing
                HStack {
                    Button("Things") { selectedTab = .things }
                        .buttonStyle(.borderedProminent)
                        .opacity(selectedTab == .things ? 1.0 : 0.7)
                    
                    Button("Types") { selectedTab = .types }
                        .buttonStyle(.borderedProminent)
                        .opacity(selectedTab == .types ? 1.0 : 0.7)
                    
                    Button("Feed") { selectedTab = .feed }
                        .buttonStyle(.borderedProminent)
                        .opacity(selectedTab == .feed ? 1.0 : 0.7)
                    
                    Button("Favorites") { selectedTab = .favorites }
                        .buttonStyle(.borderedProminent)
                        .opacity(selectedTab == .favorites ? 1.0 : 0.7)
                }
                .padding(.top, 8)
                
                // Navigation path display for debugging
                Text("Path items: \(navigationPath.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Clear Navigation") {
                    navigationPath = NavigationPath()
                }
                .font(.caption)
                .padding(.bottom, 8)
                
                // Main content
                BrowseNavigationView(
                    selectedTab: $selectedTab,
                    navigationPath: $navigationPath,
                    useSlideTransition: true,
                    onRecordTapped: { print("Record tapped") },
                    thingsContent: { ThingsView() },
                    typesContent: { TypesView() },
                    feedContent: { FeedView() },
                    favoritesContent: { FavoritesView() }
                )
                .navigationDestination(for: BrowseDestination.self) { destination in
                    DetailView(destination: destination)
                }
            }
        }
    }
} 
