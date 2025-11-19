//
//  ShareExtensionTests.swift
//  ShareExtensionTests
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Testing
import SwiftUI
import UniformTypeIdentifiers
@testable import ShareExtension

struct ShareExtensionTests {
    
    // MARK: - SharedContent Tests
    
    @Test func testSharedContentInitialization() throws {
        let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        let content = SharedContent(
            url: url,
            title: "Test Video",
            text: nil,
            image: nil,
            contentType: .youTubeVideo(videoId: "dQw4w9WgXcQ")
        )
        
        #expect(content.url == url)
        #expect(content.title == "Test Video")
        #expect(content.text == nil)
        #expect(content.image == nil)
        
        if case .youTubeVideo(let videoId) = content.contentType {
            #expect(videoId == "dQw4w9WgXcQ")
        } else {
            Issue.record("Expected YouTube video content type")
        }
    }
    
    @Test func testSharedContentDisplayTitle() throws {
        // Test with title
        let contentWithTitle = SharedContent(
            url: URL(string: "https://example.com")!,
            title: "Custom Title",
            text: nil,
            image: nil,
            contentType: .webPage
        )
        #expect(contentWithTitle.displayTitle == "Custom Title")
        
        // Test without title (should use URL host)
        let contentWithoutTitle = SharedContent(
            url: URL(string: "https://example.com/path")!,
            title: nil,
            text: nil,
            image: nil,
            contentType: .webPage
        )
        #expect(contentWithoutTitle.displayTitle == "example.com")
        
        // Test with text content
        let textContent = SharedContent(
            url: nil,
            title: nil,
            text: "Some shared text",
            image: nil,
            contentType: .text
        )
        #expect(textContent.displayTitle == "Shared Text")
    }
    
    @Test func testSharedContentDisplaySubtitle() throws {
        let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        let content = SharedContent(
            url: url,
            title: "Test Video",
            text: nil,
            image: nil,
            contentType: .youTubeVideo(videoId: "dQw4w9WgXcQ")
        )
        
        #expect(content.displaySubtitle == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    }
    
    // MARK: - ContentType Tests
    
    @Test func testContentTypeProperties() throws {
        // YouTube Video
        let youtubeType = SharedContent.ContentType.youTubeVideo(videoId: "test123")
        #expect(youtubeType.displayName == "YouTube Video")
        #expect(youtubeType.icon == "play.rectangle.fill")
        #expect(youtubeType.color == .red)
        
        // Web Page
        let webPageType = SharedContent.ContentType.webPage
        #expect(webPageType.displayName == "Web Page")
        #expect(webPageType.icon == "globe")
        #expect(webPageType.color == .blue)
        
        // Text
        let textType = SharedContent.ContentType.text
        #expect(textType.displayName == "Text")
        #expect(textType.icon == "text.alignleft")
        #expect(textType.color == .primary)
        
        // Unknown
        let unknownType = SharedContent.ContentType.unknown
        #expect(unknownType.displayName == "Unknown")
        #expect(unknownType.icon == "questionmark.circle")
        #expect(unknownType.color == .secondary)
    }
    
    // MARK: - SharedContentViewModel Tests
    
    @Test func testSharedContentViewModelInitialState() throws {
        let viewModel = SharedContentViewModel()
        
        #expect(viewModel.content == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test func testSharedContentViewModelUpdateContent() throws {
        let viewModel = SharedContentViewModel()
        let content = SharedContent(
            url: URL(string: "https://example.com")!,
            title: "Test",
            text: nil,
            image: nil,
            contentType: .webPage
        )
        
        viewModel.updateContent(content)
        
        #expect(viewModel.content != nil)
        #expect(viewModel.content?.title == "Test")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test func testSharedContentViewModelSetLoading() throws {
        let viewModel = SharedContentViewModel()
        
        viewModel.setLoading(true)
        #expect(viewModel.isLoading == true)
        #expect(viewModel.error == nil)
        
        viewModel.setLoading(false)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testSharedContentViewModelSetError() throws {
        let viewModel = SharedContentViewModel()
        
        viewModel.setError("Test error")
        #expect(viewModel.error == "Test error")
        #expect(viewModel.isLoading == false)
    }
}
