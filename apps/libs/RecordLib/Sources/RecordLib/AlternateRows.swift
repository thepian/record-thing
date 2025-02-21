//
//  AlternateRows.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 23.02.2025.
//

#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif
import SwiftUI

// Custom modifier for older SwiftUI versions that don't have .alternatingRowBackgrounds()
struct AlternatingRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if os(iOS)
                    // iOS styling
                    UITableView.appearance().backgroundColor = .systemBackground
                    UITableView.appearance().separatorColor = .separator
                    
                    // Set alternating row colors
                    UITableView.appearance().backgroundView = nil
                    UITableView.appearance().backgroundColor = nil
                    
                    let background = CALayer()
                    background.frame = CGRect(x: 0, y: 0, width: 1, height: 44)
                    
                    let alternatingColorLayer = CALayer()
                    alternatingColorLayer.frame = background.bounds
                    background.addSublayer(alternatingColorLayer)
                    
                    UITableView.appearance().backgroundView = UIView()
                    UITableView.appearance().backgroundView?.layer.addSublayer(background)
                #else
                    // macOS styling
                    if let tableView = NSApp.windows.first?.contentView?.subviews.first(where: { $0 is NSTableView }) as? NSTableView {
                        tableView.backgroundColor = .clear
                        tableView.usesAlternatingRowBackgroundColors = true
                        tableView.style = .plain
                    }
                    
                    // Optional: Set custom alternating colors
                    // NSColor.alternatingContentBackgroundColors = [
                    //     .windowBackgroundColor,
                    //     .unemphasizedSelectedContentBackgroundColor.withAlphaComponent(0.1)
                    // ]
                #endif
            }
    }
}
