# RecordLib Examples

This directory contains example implementations that demonstrate how to use various components from the RecordLib library in real-world scenarios.

## FloatingTabBarExample

The `FloatingTabBarExample.swift` file demonstrates how to create a custom TabView with a floating tab bar in SwiftUI. This component provides a modern, customizable alternative to the standard SwiftUI TabView.

### Key Features

- **Floating Tab Bar**: A tab bar that floats above the content with customizable appearance
- **Badge Support**: Support for notification badges on tab items
- **Customizable Appearance**: Extensive customization options for colors, sizes, and positioning
- **Animation**: Smooth animations when switching between tabs
- **Flexible Positioning**: Option to place the tab bar at the top or bottom of the screen

### Usage in Your Project

To implement a floating tab bar in your project:

1. Define your tab items:
   ```swift
   let tabs = [
       FloatingTabBar.TabItem(icon: "house.fill", title: "Home"),
       FloatingTabBar.TabItem(icon: "magnifyingglass", title: "Search"),
       FloatingTabBar.TabItem(icon: "camera.fill", title: "Camera"),
       FloatingTabBar.TabItem(icon: "bell.fill", title: "Notifications", badgeCount: 3),
       FloatingTabBar.TabItem(icon: "person.fill", title: "Profile")
   ]
   ```

2. Create a state variable to track the selected tab:
   ```swift
   @State private var selectedTab = 0
   ```

3. Use the FloatingTabView component:
   ```swift
   FloatingTabView(
       selectedTab: $selectedTab,
       tabs: tabs,
       tabBarBackgroundColor: Color(.systemBackground),
       tabBarSelectedColor: .blue,
       tabBarUnselectedColor: .gray
   ) {
       // Your tab content here
       // Use selectedTab to determine which content to show
   }
   ```

### Customization Options

The FloatingTabView component offers extensive customization options:

- `tabBarHeight`: Height of the tab bar
- `tabBarCornerRadius`: Corner radius of the tab bar
- `tabBarBackgroundColor`: Background color of the tab bar
- `tabBarSelectedColor`: Color of the selected tab
- `tabBarUnselectedColor`: Color of the unselected tabs
- `showTabBarShadow`: Whether to show a shadow under the tab bar
- `tabBarPosition`: Position of the tab bar (top or bottom)

## SimpleConfirmDenyStatementUsage

The `SimpleConfirmDenyStatementUsage.swift` file demonstrates how to use the `SimpleConfirmDenyStatement` component with camera frames in a Vision-based object detection app. It shows:

1. How to analyze camera frames to determine background brightness
2. How to dynamically adjust text color based on the background
3. How to apply appropriate glow effects for maximum readability against photo backgrounds

### Key Features Demonstrated

- **Dynamic Text Color**: Automatically switches between black and white text based on the background brightness
- **Glow Effect**: Adds a glow effect to text to increase contrast against photo backgrounds
- **Vision Integration**: Shows how to use Vision framework to analyze camera frames

### Implementation Details

The example includes:

- A `CameraObjectDetectionView` that simulates a camera view with object detection
- Methods for analyzing frame brightness using Vision framework
- Integration with `SimpleConfirmDenyStatement` for confirming detected objects

### Usage in Your Project

To implement similar functionality in your project:

1. Analyze your camera frames to determine background brightness using one of two approaches:

   **Core Image approach** (works on all iOS versions):
   ```swift
   let brightness = analyzeFrameBrightness(pixelBuffer: cameraPixelBuffer)
   ```

   **Vision framework approach** (iOS 15+, asynchronous):
   ```swift
   if #available(iOS 15.0, *) {
       analyzeFrameBrightnessWithVision(pixelBuffer: cameraPixelBuffer) { brightness in
           // Use brightness value here
           updateTextColor(brightness: brightness)
       }
   } else {
       // Fall back to Core Image approach for earlier iOS versions
   }
   ```
   
   **Metal approach** (efficient on all iOS versions that support Metal):
   ```swift
   analyzeFrameBrightnessWithMetal(pixelBuffer: cameraPixelBuffer) { brightness in
       // Use brightness value here
       updateTextColor(brightness: brightness)
   }
   ```

2. Use the `SimpleConfirmDenyStatement` with dynamic text color:
   ```swift
   SimpleConfirmDenyStatement(
       objectName: detectedObjectName,
       backgroundBrightness: brightness,
       useGlowEffect: true,
       glowColor: brightness > 0.5 ? .white : .black,
       onConfirm: handleConfirm,
       onDeny: handleDeny
   )
   ```

3. Alternatively, pass the camera frame directly for analysis:
   ```swift
   SimpleConfirmDenyStatement(
       objectName: detectedObjectName,
       backgroundImage: currentFrameAsUIImage,
       useGlowEffect: true,
       onConfirm: handleConfirm,
       onDeny: handleDeny
   )
   ```

### Tips for Best Results

- For dark backgrounds, use white text with a dark glow
- For light backgrounds, use black text with a light glow
- Adjust glow radius and opacity based on your specific camera conditions
- Consider the performance impact of analyzing every frame - you may want to analyze brightness less frequently
