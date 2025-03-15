//
//  RecordLib+Color.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 17.03.2025.
//

import SwiftUICore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {
    static public var adaptiveSecondaryBackground: Color {
#if os(macOS)
        return Color(NSColor.windowBackgroundColor)
#else
        return Color(.secondarySystemBackground)
#endif
    }
    
    // System backgrounds
    static public var systemBackground: Color {
#if os(macOS)
        return Color(NSColor.windowBackgroundColor)
#else
        return Color(UIColor.systemBackground)
#endif
    }
    
    static public var secondarySystemBackground: Color {
#if os(macOS)
        return Color(NSColor.controlBackgroundColor)
#else
        return Color(UIColor.secondarySystemBackground)
#endif
    }
    
    static public var tertiarySystemBackground: Color {
#if os(macOS)
        return Color(NSColor.textBackgroundColor)
#else
        return Color(UIColor.tertiarySystemBackground)
#endif
    }
}

