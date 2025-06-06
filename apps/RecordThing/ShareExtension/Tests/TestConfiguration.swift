//
//  TestConfiguration.swift
//  ShareExtensionTests
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
@testable import ShareExtension

/// Test configuration and utilities for ShareExtension tests
struct TestConfiguration {
    
    // MARK: - Test Data
    
    static let sampleYouTubeURLs = [
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://youtube.com/watch?v=dQw4w9WgXcQ",
        "https://youtu.be/dQw4w9WgXcQ",
        "https://m.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://www.youtube.com/embed/dQw4w9WgXcQ",
        "https://www.youtube.com/v/dQw4w9WgXcQ",
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s",
        "https://youtu.be/dQw4w9WgXcQ?t=30"
    ]
    
    static let sampleWebURLs = [
        "https://www.apple.com",
        "https://developer.apple.com/documentation/swiftui",
        "https://github.com/apple/swift",
        "https://stackoverflow.com/questions/tagged/swift",
        "https://www.hackingwithswift.com"
    ]
    
    static let sampleVideoIds = [
        "dQw4w9WgXcQ",
        "abc123XYZ",
        "test-video_ID",
        "1234567890A",
        "aBcDeFgHiJk"
    ]
    
    static let sampleTitles = [
        "Never Gonna Give You Up",
        "Swift Programming Tutorial",
        "iOS Development Best Practices",
        "SwiftUI Advanced Techniques",
        "Building Great Apps"
    ]
    
    static let sampleTexts = [
        "Check out this amazing video: https://youtu.be/dQw4w9WgXcQ",
        "Here's a great article about Swift programming",
        "Don't forget to watch this tutorial",
        "This is some shared text content",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
    ]
    
    // MARK: - Factory Methods
    
    /// Creates a sample YouTube SharedContent for testing
    static func createYouTubeContent(
        videoId: String = "dQw4w9WgXcQ",
        title: String = "Test Video",
        url: URL? = nil
    ) -> SharedContent {
        let contentURL = url ?? URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
        
        return SharedContent(
            url: contentURL,
            title: title,
            text: nil,
            image: nil,
            contentType: .youTubeVideo(videoId: videoId)
        )
    }
    
    /// Creates a sample web page SharedContent for testing
    static func createWebPageContent(
        url: URL = URL(string: "https://example.com")!,
        title: String = "Example Website"
    ) -> SharedContent {
        return SharedContent(
            url: url,
            title: title,
            text: nil,
            image: nil,
            contentType: .webPage
        )
    }
    
    /// Creates a sample text SharedContent for testing
    static func createTextContent(
        text: String = "Sample shared text"
    ) -> SharedContent {
        return SharedContent(
            url: nil,
            title: nil,
            text: text,
            image: nil,
            contentType: .text
        )
    }
    
    /// Creates a sample unknown content for testing
    static func createUnknownContent() -> SharedContent {
        return SharedContent(
            url: nil,
            title: nil,
            text: nil,
            image: nil,
            contentType: .unknown
        )
    }
    
    // MARK: - Test Utilities
    
    /// Validates that a URL is a valid YouTube URL
    static func isValidYouTubeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return YouTubeService.isYouTubeURL(url)
    }
    
    /// Extracts video ID from a YouTube URL string
    static func extractVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return YouTubeService.extractVideoID(from: url)
    }
    
    /// Creates a mock SharedContentViewModel with test data
    static func createMockViewModel(with content: SharedContent? = nil) -> SharedContentViewModel {
        let viewModel = SharedContentViewModel()
        
        if let content = content {
            viewModel.updateContent(content)
        }
        
        return viewModel
    }
    
    /// Creates a mock SharedContentViewModel in loading state
    static func createLoadingViewModel() -> SharedContentViewModel {
        let viewModel = SharedContentViewModel()
        viewModel.setLoading(true)
        return viewModel
    }
    
    /// Creates a mock SharedContentViewModel in error state
    static func createErrorViewModel(error: String = "Test error") -> SharedContentViewModel {
        let viewModel = SharedContentViewModel()
        viewModel.setError(error)
        return viewModel
    }
    
    // MARK: - Assertion Helpers
    
    /// Validates that SharedContent has expected YouTube properties
    static func validateYouTubeContent(
        _ content: SharedContent,
        expectedVideoId: String,
        expectedTitle: String? = nil
    ) -> Bool {
        guard case .youTubeVideo(let videoId) = content.contentType else {
            return false
        }
        
        guard videoId == expectedVideoId else {
            return false
        }
        
        if let expectedTitle = expectedTitle {
            guard content.title == expectedTitle else {
                return false
            }
        }
        
        return true
    }
    
    /// Validates that SharedContent has expected web page properties
    static func validateWebPageContent(
        _ content: SharedContent,
        expectedURL: URL,
        expectedTitle: String? = nil
    ) -> Bool {
        guard case .webPage = content.contentType else {
            return false
        }
        
        guard content.url == expectedURL else {
            return false
        }
        
        if let expectedTitle = expectedTitle {
            guard content.title == expectedTitle else {
                return false
            }
        }
        
        return true
    }
    
    /// Validates that SharedContent has expected text properties
    static func validateTextContent(
        _ content: SharedContent,
        expectedText: String
    ) -> Bool {
        guard case .text = content.contentType else {
            return false
        }
        
        return content.text == expectedText
    }
}
