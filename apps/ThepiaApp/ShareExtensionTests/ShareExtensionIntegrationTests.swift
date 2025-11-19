//
//  ShareExtensionIntegrationTests.swift
//  ShareExtensionTests
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Testing
import Foundation
import UniformTypeIdentifiers
@testable import ShareExtension

struct ShareExtensionIntegrationTests {
    
    // MARK: - End-to-End YouTube Sharing Tests
    
    @Test func testYouTubeVideoSharingWorkflow() async throws {
        let youtubeURL = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
        
        // Step 1: Verify URL recognition
        #expect(YouTubeService.isYouTubeURL(youtubeURL) == true)
        
        // Step 2: Extract video ID
        let videoId = YouTubeService.extractVideoID(from: youtubeURL)
        #expect(videoId == "dQw4w9WgXcQ")
        
        // Step 3: Create content type
        let contentType = SharedContent.ContentType.youTubeVideo(videoId: videoId!)
        #expect(contentType.displayName == "YouTube Video")
        
        // Step 4: Create shared content
        let sharedContent = SharedContent(
            url: youtubeURL,
            title: "Never Gonna Give You Up",
            text: nil,
            image: nil,
            contentType: contentType
        )
        
        #expect(sharedContent.displayTitle == "Never Gonna Give You Up")
        #expect(sharedContent.displaySubtitle == youtubeURL.absoluteString)
        
        // Step 5: Test view model integration
        let viewModel = SharedContentViewModel()
        viewModel.updateContent(sharedContent)
        
        #expect(viewModel.content != nil)
        #expect(viewModel.content?.title == "Never Gonna Give You Up")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test func testWebPageSharingWorkflow() async throws {
        let webURL = URL(string: "https://www.apple.com/iphone")!
        
        // Step 1: Verify it's not a YouTube URL
        #expect(YouTubeService.isYouTubeURL(webURL) == false)
        
        // Step 2: Create web page content
        let sharedContent = SharedContent(
            url: webURL,
            title: "iPhone - Apple",
            text: nil,
            image: nil,
            contentType: .webPage
        )
        
        #expect(sharedContent.displayTitle == "iPhone - Apple")
        #expect(sharedContent.displaySubtitle == webURL.absoluteString)
        
        // Step 3: Test view model integration
        let viewModel = SharedContentViewModel()
        viewModel.updateContent(sharedContent)
        
        #expect(viewModel.content != nil)
        #expect(viewModel.content?.title == "iPhone - Apple")
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testTextSharingWorkflow() async throws {
        let sharedText = "Check out this amazing article: https://example.com/article"
        
        // Step 1: Create text content
        let sharedContent = SharedContent(
            url: nil,
            title: nil,
            text: sharedText,
            image: nil,
            contentType: .text
        )
        
        #expect(sharedContent.displayTitle == "Shared Text")
        #expect(sharedContent.displaySubtitle == nil)
        
        // Step 2: Test view model integration
        let viewModel = SharedContentViewModel()
        viewModel.updateContent(sharedContent)
        
        #expect(viewModel.content != nil)
        #expect(viewModel.content?.text == sharedText)
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testErrorHandlingWorkflow() async throws {
        let viewModel = SharedContentViewModel()
        
        // Test loading state
        viewModel.setLoading(true)
        #expect(viewModel.isLoading == true)
        #expect(viewModel.error == nil)
        
        // Test error state
        viewModel.setError("Failed to load content")
        #expect(viewModel.error == "Failed to load content")
        #expect(viewModel.isLoading == false)
        
        // Test recovery from error
        let validContent = SharedContent(
            url: URL(string: "https://example.com")!,
            title: "Test",
            text: nil,
            image: nil,
            contentType: .webPage
        )
        
        viewModel.updateContent(validContent)
        #expect(viewModel.content != nil)
        #expect(viewModel.error == nil)
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - ShareExtensionView Integration Tests
    
    @Test func testShareExtensionViewCallbacks() async throws {
        var saveCallCount = 0
        var cancelCallCount = 0
        var contentUpdateCallCount = 0
        var savedNote = ""
        var updatedViewModel: SharedContentViewModel?
        
        let view = ShareExtensionView(
            onSave: { note in
                saveCallCount += 1
                savedNote = note
            },
            onCancel: {
                cancelCallCount += 1
            },
            onContentUpdate: { viewModel in
                contentUpdateCallCount += 1
                updatedViewModel = viewModel
            }
        )
        
        // View should initialize and trigger content update
        #expect(view != nil)
        
        // Simulate content update
        if let viewModel = updatedViewModel {
            let testContent = SharedContent(
                url: URL(string: "https://www.youtube.com/watch?v=test123")!,
                title: "Test Video",
                text: nil,
                image: nil,
                contentType: .youTubeVideo(videoId: "test123")
            )
            
            viewModel.updateContent(testContent)
            #expect(viewModel.content?.title == "Test Video")
        }
    }
    
    // MARK: - Multiple URL Format Tests
    
    @Test func testMultipleYouTubeURLFormats() async throws {
        let urlFormats = [
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "https://youtube.com/watch?v=dQw4w9WgXcQ",
            "https://youtu.be/dQw4w9WgXcQ",
            "https://m.youtube.com/watch?v=dQw4w9WgXcQ",
            "https://www.youtube.com/embed/dQw4w9WgXcQ",
            "https://www.youtube.com/v/dQw4w9WgXcQ"
        ]
        
        for urlString in urlFormats {
            let url = URL(string: urlString)!
            
            // All should be recognized as YouTube URLs
            #expect(YouTubeService.isYouTubeURL(url) == true)
            
            // All should extract the same video ID
            let videoId = YouTubeService.extractVideoID(from: url)
            #expect(videoId == "dQw4w9WgXcQ")
            
            // All should create valid shared content
            let content = SharedContent(
                url: url,
                title: "Test Video",
                text: nil,
                image: nil,
                contentType: .youTubeVideo(videoId: videoId!)
            )
            
            #expect(content.displayTitle == "Test Video")
            #expect(content.displaySubtitle == url.absoluteString)
        }
    }
    
    // MARK: - Thumbnail URL Generation Tests
    
    @Test func testThumbnailURLGeneration() async throws {
        let videoId = "dQw4w9WgXcQ"
        let qualities: [YouTubeService.ThumbnailQuality] = [.default, .medium, .high, .standard, .maxRes]
        
        for quality in qualities {
            let thumbnailURL = YouTubeService.thumbnailURL(for: videoId, quality: quality)
            
            // URL should be valid
            #expect(thumbnailURL.scheme == "https")
            #expect(thumbnailURL.host == "img.youtube.com")
            #expect(thumbnailURL.path.contains(videoId))
            
            // URL should contain quality indicator
            switch quality {
            case .default:
                #expect(thumbnailURL.path.contains("default.jpg"))
            case .medium:
                #expect(thumbnailURL.path.contains("mqdefault.jpg"))
            case .high:
                #expect(thumbnailURL.path.contains("hqdefault.jpg"))
            case .standard:
                #expect(thumbnailURL.path.contains("sddefault.jpg"))
            case .maxRes:
                #expect(thumbnailURL.path.contains("maxresdefault.jpg"))
            }
        }
    }
}
