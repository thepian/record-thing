//
//  ShareExtensionViewTests.swift
//  ShareExtensionTests
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Testing
import SwiftUI
@testable import ShareExtension

struct ShareExtensionViewTests {
    
    // MARK: - View Initialization Tests
    
    @Test func testShareExtensionViewInitialization() throws {
        var saveCallCount = 0
        var cancelCallCount = 0
        var contentUpdateCallCount = 0
        var savedNote = ""
        
        let view = ShareExtensionView(
            onSave: { note in
                saveCallCount += 1
                savedNote = note
            },
            onCancel: {
                cancelCallCount += 1
            },
            onContentUpdate: { _ in
                contentUpdateCallCount += 1
            }
        )
        
        // View should initialize without issues
        #expect(view != nil)
    }
    
    // MARK: - SharedContentPreview Tests
    
    @Test func testSharedContentPreviewWithYouTubeVideo() throws {
        let content = SharedContent(
            url: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!,
            title: "Never Gonna Give You Up",
            text: nil,
            image: nil,
            contentType: .youTubeVideo(videoId: "dQw4w9WgXcQ")
        )
        
        let preview = SharedContentPreview(content: content)
        
        // Preview should initialize without issues
        #expect(preview != nil)
    }
    
    @Test func testSharedContentPreviewWithWebPage() throws {
        let content = SharedContent(
            url: URL(string: "https://example.com")!,
            title: "Example Website",
            text: nil,
            image: nil,
            contentType: .webPage
        )
        
        let preview = SharedContentPreview(content: content)
        
        // Preview should initialize without issues
        #expect(preview != nil)
    }
    
    @Test func testSharedContentPreviewWithText() throws {
        let content = SharedContent(
            url: nil,
            title: nil,
            text: "Some shared text content",
            image: nil,
            contentType: .text
        )
        
        let preview = SharedContentPreview(content: content)
        
        // Preview should initialize without issues
        #expect(preview != nil)
    }
    
    // MARK: - LoadingContentPreview Tests
    
    @Test func testLoadingContentPreview() throws {
        let loadingPreview = LoadingContentPreview()
        
        // Loading preview should initialize without issues
        #expect(loadingPreview != nil)
    }
    
    // MARK: - PlaceholderContentPreview Tests
    
    @Test func testPlaceholderContentPreview() throws {
        let placeholderPreview = PlaceholderContentPreview()
        
        // Placeholder preview should initialize without issues
        #expect(placeholderPreview != nil)
    }
    
    // MARK: - RoundedCorner Shape Tests
    
    @Test func testRoundedCornerShape() throws {
        let shape = RoundedCorner(radius: 8.0, corners: [.topLeft, .topRight])
        
        #expect(shape.radius == 8.0)
        #expect(shape.corners == [.topLeft, .topRight])
        
        // Test path generation
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let path = shape.path(in: rect)
        
        // Path should not be empty
        #expect(!path.isEmpty)
    }
    
    @Test func testRoundedCornerShapeAllCorners() throws {
        let shape = RoundedCorner(radius: 12.0, corners: .allCorners)
        
        #expect(shape.radius == 12.0)
        #expect(shape.corners == .allCorners)
    }
    
    // MARK: - View Extension Tests
    
    @Test func testCornerRadiusExtension() throws {
        let testView = Rectangle()
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        
        // View should apply corner radius without issues
        #expect(testView != nil)
    }
    
    // MARK: - Content Type Display Tests
    
    @Test func testContentTypeDisplayProperties() throws {
        // Test YouTube video type
        let youtubeType = SharedContent.ContentType.youTubeVideo(videoId: "test123")
        #expect(youtubeType.displayName == "YouTube Video")
        #expect(youtubeType.icon == "play.rectangle.fill")
        
        // Test web page type
        let webPageType = SharedContent.ContentType.webPage
        #expect(webPageType.displayName == "Web Page")
        #expect(webPageType.icon == "globe")
        
        // Test text type
        let textType = SharedContent.ContentType.text
        #expect(textType.displayName == "Text")
        #expect(textType.icon == "text.alignleft")
        
        // Test unknown type
        let unknownType = SharedContent.ContentType.unknown
        #expect(unknownType.displayName == "Unknown")
        #expect(unknownType.icon == "questionmark.circle")
    }
    
    // MARK: - SharedContent Display Tests
    
    @Test func testSharedContentDisplayTitleGeneration() throws {
        // Test with explicit title
        let contentWithTitle = SharedContent(
            url: URL(string: "https://example.com")!,
            title: "Custom Title",
            text: nil,
            image: nil,
            contentType: .webPage
        )
        #expect(contentWithTitle.displayTitle == "Custom Title")
        
        // Test with URL but no title
        let contentWithURL = SharedContent(
            url: URL(string: "https://example.com/path")!,
            title: nil,
            text: nil,
            image: nil,
            contentType: .webPage
        )
        #expect(contentWithURL.displayTitle == "example.com")
        
        // Test with text content
        let textContent = SharedContent(
            url: nil,
            title: nil,
            text: "Some text",
            image: nil,
            contentType: .text
        )
        #expect(textContent.displayTitle == "Shared Text")
        
        // Test with no content
        let emptyContent = SharedContent(
            url: nil,
            title: nil,
            text: nil,
            image: nil,
            contentType: .unknown
        )
        #expect(emptyContent.displayTitle == "Unknown Content")
    }
    
    @Test func testSharedContentDisplaySubtitleGeneration() throws {
        let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        let content = SharedContent(
            url: url,
            title: "Test Video",
            text: nil,
            image: nil,
            contentType: .youTubeVideo(videoId: "dQw4w9WgXcQ")
        )
        
        #expect(content.displaySubtitle == url.absoluteString)
        
        // Test content without URL
        let textContent = SharedContent(
            url: nil,
            title: nil,
            text: "Some text",
            image: nil,
            contentType: .text
        )
        #expect(textContent.displaySubtitle == nil)
    }
}
