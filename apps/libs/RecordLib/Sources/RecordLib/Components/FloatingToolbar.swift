//
//  FloatingToolbar.swift
//  RecordLib
//
//  Created by Cline on 05.03.2025.
//

import SwiftUI
import os

/// A floating toolbar with configurable buttons that can be used within a NavigationStack
public struct FloatingToolbar<Content: View>: View {
    // Debug logs for initialization
    private let logger = Logger(subsystem: "com.evidently.recordthing", category: "FloatingToolbar")
    
    // Properties
    private let content: Content
    private let backgroundColor: Color
    private let opacity: Double
    private let cornerRadius: CGFloat
    private let height: CGFloat
    private let padding: EdgeInsets
    private let useFullRounding: Bool
    
    /// Creates a new FloatingToolbar with custom content
    /// - Parameters:
    ///   - backgroundColor: Background color of the toolbar
    ///   - opacity: Opacity of the toolbar background
    ///   - cornerRadius: Corner radius of the toolbar
    ///   - height: Height of the toolbar
    ///   - padding: Padding around the toolbar
    ///   - useFullRounding: If true, uses a pill shape (Capsule), otherwise uses the specified cornerRadius
    ///   - content: Content to display in the toolbar
    public init(
        backgroundColor: Color = .black,
        opacity: Double = 0.3,
        cornerRadius: CGFloat = 10,
        height: CGFloat = 60,
        padding: EdgeInsets = EdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20),
        useFullRounding: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.height = height
        self.padding = padding
        self.useFullRounding = useFullRounding
        self.content = content()
//        logger.trace("FloatingToolbar initialized with cornerRadius: \(cornerRadius), useFullRounding: \(useFullRounding)")
    }
    
    public var body: some View {
        VStack {
            Spacer()
            
            // Toolbar container
            HStack {
                content
            }
            .frame(height: height)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if useFullRounding {
                        Capsule()
                            .fill(backgroundColor.opacity(opacity))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(backgroundColor.opacity(opacity))
                    }
                }
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .padding(padding)
        }
    }
}

/// A standard camera button for the floating toolbar
public struct CameraButton: View {
    private let action: () -> Void
    private let size: CGFloat
    
    /// Creates a new CameraButton
    /// - Parameters:
    ///   - size: Size of the button
    ///   - action: Action to perform when the button is tapped
    public init(size: CGFloat = 50, action: @escaping () -> Void) {
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            if false {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                            .padding(4)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: size - 8, height: size - 8)
                    )

            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Take Picture")
    }
}

public struct DataBrowseButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "filemenu.and.selection")
                .font(.system(size: 22))
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Data browse")
    }
}

/// A standard stack button for the floating toolbar
public struct StackButton: View {
    private let action: () -> Void
    
    /// Creates a new StackButton
    /// - Parameter action: Action to perform when the button is tapped
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 22))
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stack")
    }
}

/// A standard account/signature button for the floating toolbar
public struct AccountButton: View {
    private let action: () -> Void
    
    /// Creates a new AccountButton
    /// - Parameter action: Action to perform when the button is tapped
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: "signature")
                .font(.system(size: 22))
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Account")
    }
}

/// A standard floating toolbar with Stack, Camera, and Account buttons
public struct StandardFloatingToolbar: View {
    private let onDataBrowseTapped: (() -> Void)?
    private let onStackTapped: () -> Void
    private let onCameraTapped: () -> Void
    private let onAccountTapped: () -> Void
    private let backgroundColor: Color
    private let opacity: Double
    private let cornerRadius: CGFloat
    private let useFullRounding: Bool
    private let spacing: CGFloat
    
    /// Creates a new StandardFloatingToolbar
    /// - Parameters:
    ///   - backgroundColor: Background color of the toolbar
    ///   - opacity: Opacity of the toolbar background
    ///   - cornerRadius: Corner radius of the toolbar (used when useFullRounding is false)
    ///   - useFullRounding: If true, uses a pill shape, otherwise uses the specified cornerRadius
    ///   - spacing: Spacing between toolbar items
    ///   - showDataBrowseButton: Whether to show the data browse button
    ///   - onDataBrowseTapped: Action to perform when the data browse button is tapped (nil if button is hidden)
    ///   - onStackTapped: Action to perform when the stack button is tapped
    ///   - onCameraTapped: Action to perform when the camera button is tapped
    ///   - onAccountTapped: Action to perform when the account button is tapped
    public init(
        backgroundColor: Color = .black,
        opacity: Double = 0.3,
        cornerRadius: CGFloat = 20,
        useFullRounding: Bool = true,
        spacing: CGFloat = 32,
        showDataBrowseButton: Bool = true,
        onDataBrowseTapped: (() -> Void)? = nil,
        onStackTapped: @escaping () -> Void,
        onCameraTapped: @escaping () -> Void,
        onAccountTapped: @escaping () -> Void
    ) {
        self.backgroundColor = backgroundColor
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.useFullRounding = useFullRounding
        self.spacing = spacing
        self.onDataBrowseTapped = showDataBrowseButton ? onDataBrowseTapped : nil
        self.onStackTapped = onStackTapped
        self.onCameraTapped = onCameraTapped
        self.onAccountTapped = onAccountTapped
    }
    
    public var body: some View {
        FloatingToolbar(
            backgroundColor: backgroundColor,
            opacity: opacity,
            cornerRadius: cornerRadius,
            useFullRounding: useFullRounding
        ) {
            HStack(spacing: spacing) {
                // Left side - Data Browse Button or placeholder
                if let dataBrowseAction = onDataBrowseTapped {
                    DataBrowseButton(action: dataBrowseAction)
                } else {
                    Color.clear
                        .frame(width: 22, height: 22) // Same size as the icon
                }
                
                // Center items
                StackButton(action: onStackTapped)
                
                // Camera button (larger, centered)
                CameraButton(action: onCameraTapped)
                
                // Right side items
                AccountButton(action: onAccountTapped)
                
                // Right side placeholder (only if data browse button is shown)
                if onDataBrowseTapped != nil {
                    Color.clear
                        .frame(width: 22, height: 22) // Same size as the icon
                }
            }
            .padding(.horizontal, 16)
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
#if DEBUG
struct FloatingToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background content (would be the camera in the real app)
            GeometryReader { geometry in
                Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // This prevents the image from overflowing
            }
            .ignoresSafeArea()
            
            VStack {
                // The floating toolbar without data browse button
                StandardFloatingToolbar(
                    useFullRounding: true,
                    showDataBrowseButton: false,
                    onStackTapped: { print("Stack tapped") },
                    onCameraTapped: { print("Camera tapped") },
                    onAccountTapped: { print("Account tapped") }
                )
                .padding(.top, 20)
                
                SimpleConfirmDenyStatement(
                    objectName: "Electric Mountain Bike",
                    onConfirm: { print("Confirmed electric mountain bike") },
                    onDeny: { print("Denied electric mountain bike") }
                )
                .padding()
            }
            
        }
        .previewDisplayName("Standard Toolbar")
        
        ZStack {
            // Background content (would be the camera in the real app)
            GeometryReader { geometry in
                Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // This prevents the image from overflowing
            }
            .ignoresSafeArea()
            
            VStack {
                // The floating toolbar with data browse button
                StandardFloatingToolbar(
                    useFullRounding: false,
                    showDataBrowseButton: true,
                    onDataBrowseTapped: { print("Browse tapped") },
                    onStackTapped: { print("Stack tapped") },
                    onCameraTapped: { print("Camera tapped") },
                    onAccountTapped: { print("Account tapped") }
                )
                
                SimpleConfirmDenyStatement(
                    objectName: "Electric Mountain Bike",
                    onConfirm: { print("Confirmed electric mountain bike") },
                    onDeny: { print("Denied electric mountain bike") }
                )
                .padding()
            }
            
        }
        .previewDisplayName("Extended Toolbar")
        
        ZStack {
            // Background content using the mountain bike image
            GeometryReader { geometry in
                Image("thepia_a_high-end_electric_mountain_bike_2", bundle: Bundle.module)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // This prevents the image from overflowing
            }
            .ignoresSafeArea()
            
            // Custom floating toolbar
            FloatingToolbar {
                HStack {
                    Spacer()
                    Button(action: { print("Custom button 1") }) {
                        Image(systemName: "folder")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    CameraButton(action: { print("Camera tapped") })
                    Spacer()
                    Button(action: { print("Custom button 2") }) {
                        Image(systemName: "gear")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .previewDisplayName("Custom Toolbar")
    }
}
#endif
