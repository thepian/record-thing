//
//  FloatingTabBarExample.swift
//  RecordLib
//
//  Created by Cline on 10.03.2025.
//

import SwiftUI

/// A custom floating tab bar component for SwiftUI
public struct FloatingTabBar: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "FloatingTabBar")
    
    // Properties
    @Binding private var selectedTab: Int
    private let tabs: [TabItem]
    private let height: CGFloat
    private let cornerRadius: CGFloat
    private let backgroundColor: Color
    private let selectedColor: Color
    private let unselectedColor: Color
    private let showShadow: Bool
    
    /// A tab item for the floating tab bar
    public struct TabItem {
        let icon: String // SF Symbol name
        let title: String
        let badgeCount: Int?
        
        public init(icon: String, title: String, badgeCount: Int? = nil) {
            self.icon = icon
            self.title = title
            self.badgeCount = badgeCount
        }
    }
    
    /// Creates a new FloatingTabBar
    /// - Parameters:
    ///   - selectedTab: Binding to the selected tab index
    ///   - tabs: Array of tab items to display
    ///   - height: Height of the tab bar
    ///   - cornerRadius: Corner radius of the tab bar
    ///   - backgroundColor: Background color of the tab bar
    ///   - selectedColor: Color of the selected tab
    ///   - unselectedColor: Color of the unselected tabs
    ///   - showShadow: Whether to show a shadow under the tab bar
    public init(
        selectedTab: Binding<Int>,
        tabs: [TabItem],
        height: CGFloat = 60,
        cornerRadius: CGFloat = 25,
        backgroundColor: Color = Color(.systemBackground),
        selectedColor: Color = .blue,
        unselectedColor: Color = .gray,
        showShadow: Bool = true
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.height = height
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.selectedColor = selectedColor
        self.unselectedColor = unselectedColor
        self.showShadow = showShadow
        
        logger.debug("FloatingTabBar initialized with \(tabs.count) tabs")
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = index
                    }
                    logger.debug("Tab selected: \(tabs[index].title)")
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == index ? selectedColor : unselectedColor)
                            
                            // Badge indicator if needed
                            if let badgeCount = tabs[index].badgeCount, badgeCount > 0 {
                                Text("\(badgeCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                        
                        Text(tabs[index].title)
                            .font(.system(size: 12))
                            .foregroundColor(selectedTab == index ? selectedColor : unselectedColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == index ?
                            selectedColor.opacity(0.1) :
                            Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(height: height)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .shadow(color: showShadow ? Color.black.opacity(0.15) : Color.clear, radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}

/// A custom tab view with a floating tab bar
public struct FloatingTabView<Content: View>: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "FloatingTabView")
    
    // Properties
    @Binding private var selectedTab: Int
    private let tabs: [FloatingTabBar.TabItem]
    private let content: Content
    private let tabBarHeight: CGFloat
    private let tabBarCornerRadius: CGFloat
    private let tabBarBackgroundColor: Color
    private let tabBarSelectedColor: Color
    private let tabBarUnselectedColor: Color
    private let showTabBarShadow: Bool
    private let tabBarPosition: TabBarPosition
    
    // Track previous tab for slide direction
    @State private var previousTab: Int
    
    /// Position of the tab bar
    public enum TabBarPosition {
        case bottom
        case top
    }
    
    /// Creates a new FloatingTabView
    /// - Parameters:
    ///   - selectedTab: Binding to the selected tab index
    ///   - tabs: Array of tab items to display
    ///   - tabBarHeight: Height of the tab bar
    ///   - tabBarCornerRadius: Corner radius of the tab bar
    ///   - tabBarBackgroundColor: Background color of the tab bar
    ///   - tabBarSelectedColor: Color of the selected tab
    ///   - tabBarUnselectedColor: Color of the unselected tabs
    ///   - showTabBarShadow: Whether to show a shadow under the tab bar
    ///   - tabBarPosition: Position of the tab bar (top or bottom)
    ///   - content: Content of the tab view
    public init(
        selectedTab: Binding<Int>,
        tabs: [FloatingTabBar.TabItem],
        tabBarHeight: CGFloat = 60,
        tabBarCornerRadius: CGFloat = 25,
        tabBarBackgroundColor: Color = Color(.systemBackground),
        tabBarSelectedColor: Color = .blue,
        tabBarUnselectedColor: Color = .gray,
        showTabBarShadow: Bool = true,
        tabBarPosition: TabBarPosition = .bottom,
        @ViewBuilder content: () -> Content
    ) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.tabBarHeight = tabBarHeight
        self.tabBarCornerRadius = tabBarCornerRadius
        self.tabBarBackgroundColor = tabBarBackgroundColor
        self.tabBarSelectedColor = tabBarSelectedColor
        self.tabBarUnselectedColor = tabBarUnselectedColor
        self.showTabBarShadow = showTabBarShadow
        self.tabBarPosition = tabBarPosition
        self.content = content()
        self._previousTab = State(initialValue: selectedTab.wrappedValue)
        
        logger.debug("FloatingTabView initialized with \(tabs.count) tabs")
    }
    
    public var body: some View {
        ZStack(alignment: tabBarPosition == .bottom ? .bottom : .top) {
            // Main content with sliding transition
            TabViewWithSlideTransition(
                selectedTab: $selectedTab,
                previousTab: $previousTab,
                content: content
            )
            .padding(.bottom, tabBarPosition == .bottom ? tabBarHeight + 16 : 0)
            .padding(.top, tabBarPosition == .top ? tabBarHeight + 16 : 0)
            
            // Floating tab bar
            FloatingTabBar(
                selectedTab: Binding(
                    get: { selectedTab },
                    set: { newValue in
                        previousTab = selectedTab
                        selectedTab = newValue
                    }
                ),
                tabs: tabs,
                height: tabBarHeight,
                cornerRadius: tabBarCornerRadius,
                backgroundColor: tabBarBackgroundColor,
                selectedColor: tabBarSelectedColor,
                unselectedColor: tabBarUnselectedColor,
                showShadow: showTabBarShadow
            )
            .padding(.bottom, tabBarPosition == .bottom ? 8 : 0)
            .padding(.top, tabBarPosition == .top ? 8 : 0)
        }
    }
}

/// A custom view that provides sliding transitions between tabs
private struct TabViewWithSlideTransition<Content: View>: View {
    @Binding var selectedTab: Int
    @Binding var previousTab: Int
    let content: Content
    
    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: CGFloat(previousTab - selectedTab) * geometry.size.width)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .onChange(of: selectedTab) { newValue in
                    // Update previous tab after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        previousTab = newValue
                    }
                }
        }
    }
}

/// Example usage of the FloatingTabView
public struct FloatingTabBarExample: View {
    // State
    @State private var selectedTab = 0
    
    // Tab items
    private let tabs = [
        FloatingTabBar.TabItem(icon: "house.fill", title: "Home"),
        FloatingTabBar.TabItem(icon: "magnifyingglass", title: "Search"),
        FloatingTabBar.TabItem(icon: "camera.fill", title: "Camera"),
        FloatingTabBar.TabItem(icon: "bell.fill", title: "Notifications", badgeCount: 3),
        FloatingTabBar.TabItem(icon: "person.fill", title: "Profile")
    ]
    
    public init() {}
    
    public var body: some View {
        FloatingTabView(
            selectedTab: $selectedTab,
            tabs: tabs,
            tabBarBackgroundColor: Color(.systemBackground),
            tabBarSelectedColor: .blue,
            tabBarUnselectedColor: .gray
        ) {
            // Tab content
            TabContentView(selectedTab: selectedTab, tabs: tabs)
        }
    }
}

/// Separate view for tab content to improve performance
private struct TabContentView: View {
    let selectedTab: Int
    let tabs: [FloatingTabBar.TabItem]
    
    var body: some View {
        ZStack {
            // Background color changes based on selected tab
            [Color.blue.opacity(0.1), 
             Color.green.opacity(0.1), 
             Color.orange.opacity(0.1),
             Color.purple.opacity(0.1),
             Color.pink.opacity(0.1)][selectedTab]
                .ignoresSafeArea()
            
            // Tab content
            VStack {
                Text(tabs[selectedTab].title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Image(systemName: tabs[selectedTab].icon)
                    .font(.system(size: 72))
                    .padding()
                
                Text("Tab \(selectedTab + 1) Content")
                    .font(.title2)
            }
        }
    }
}

// Simple logger for debugging
fileprivate struct Logger {
    let subsystem: String
    let category: String
    
    func debug(_ message: String) {
        #if DEBUG
        print("[\(subsystem):\(category)] DEBUG: \(message)")
        #endif
    }
}

// MARK: - Preview
struct FloatingTabBarExample_Previews: PreviewProvider {
    static var previews: some View {
        FloatingTabBarExample()
    }
}
