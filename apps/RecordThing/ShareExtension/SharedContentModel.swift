//
//  SharedContentModel.swift
//  ShareExtension
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
import SwiftUI

/// Represents content shared to the RecordThing ShareExtension
struct SharedContent: Identifiable {
    let id = UUID()
    let url: URL?
    let title: String?
    let text: String?
    let image: UIImage?
    let contentType: ContentType
    
    enum ContentType {
        case youTubeVideo(videoId: String)
        case webPage
        case image
        case text
        case unknown
        
        var icon: String {
            switch self {
            case .youTubeVideo:
                return "play.rectangle.fill"
            case .webPage:
                return "globe"
            case .image:
                return "photo"
            case .text:
                return "text.alignleft"
            case .unknown:
                return "questionmark.circle"
            }
        }
        
        var displayName: String {
            switch self {
            case .youTubeVideo:
                return "YouTube Video"
            case .webPage:
                return "Web Page"
            case .image:
                return "Image"
            case .text:
                return "Text"
            case .unknown:
                return "Content"
            }
        }
        
        var color: Color {
            switch self {
            case .youTubeVideo:
                return .red
            case .webPage:
                return Color.accentColor
            case .image:
                return .green
            case .text:
                return .orange
            case .unknown:
                return .gray
            }
        }
    }
    
    /// Display title for the content
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        
        if let url = url {
            if case .youTubeVideo(let videoId) = contentType {
                return "YouTube Video (\(videoId))"
            }
            return url.host ?? url.absoluteString
        }
        
        if let text = text, !text.isEmpty {
            return String(text.prefix(50)) + (text.count > 50 ? "..." : "")
        }
        
        return "Shared Content"
    }
    
    /// Display subtitle for the content
    var displaySubtitle: String? {
        if let url = url {
            return url.absoluteString
        }
        return nil
    }
    
    /// Hero image for display
    var heroImage: UIImage? {
        return image
    }
    
    /// Placeholder hero image when no image is available
    var placeholderHeroImage: UIImage? {
        // Generate a simple placeholder based on content type
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor(contentType.color).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Icon
            let iconSize: CGFloat = 60
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            UIColor.white.setFill()
            let iconPath = UIBezierPath(ovalIn: iconRect)
            iconPath.fill()
        }
    }
}

/// Observable class to manage shared content state
@MainActor
class SharedContentViewModel: ObservableObject {
    @Published var content: SharedContent?
    @Published var isLoading = false
    @Published var error: String?
    
    func updateContent(_ content: SharedContent) {
        self.content = content
    }
    
    func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }
    
    func setError(_ error: String?) {
        self.error = error
    }
}
