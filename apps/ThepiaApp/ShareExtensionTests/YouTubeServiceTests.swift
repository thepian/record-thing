//
//  YouTubeServiceTests.swift
//  ShareExtensionTests
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
import Testing

@testable import ShareExtension

struct YouTubeServiceTests {

  // MARK: - URL Recognition Tests

  @Test func testIsYouTubeURL() throws {
    // Valid YouTube URLs
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!)
        == true)
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://youtube.com/watch?v=dQw4w9WgXcQ")!) == true)
    #expect(YouTubeService.isYouTubeURL(URL(string: "https://youtu.be/dQw4w9WgXcQ")!) == true)
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://m.youtube.com/watch?v=dQw4w9WgXcQ")!) == true
    )
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://www.youtube.com/embed/dQw4w9WgXcQ")!) == true
    )
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://www.youtube.com/v/dQw4w9WgXcQ")!) == true)

    // Invalid URLs
    #expect(YouTubeService.isYouTubeURL(URL(string: "https://www.google.com")!) == false)
    #expect(YouTubeService.isYouTubeURL(URL(string: "https://www.vimeo.com/123456")!) == false)
    #expect(YouTubeService.isYouTubeURL(URL(string: "https://example.com")!) == false)
  }

  @Test func testExtractVideoID() throws {
    // Standard watch URLs
    #expect(
      YouTubeService.extractVideoID(
        from: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!) == "dQw4w9WgXcQ")
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://youtube.com/watch?v=abc123XYZ")!)
        == "abc123XYZ")

    // Short URLs
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://youtu.be/dQw4w9WgXcQ")!)
        == "dQw4w9WgXcQ")
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://youtu.be/abc123XYZ?t=30")!)
        == "abc123XYZ")

    // Embed URLs
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/embed/dQw4w9WgXcQ")!)
        == "dQw4w9WgXcQ")
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/v/dQw4w9WgXcQ")!)
        == "dQw4w9WgXcQ")

    // Mobile URLs
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://m.youtube.com/watch?v=dQw4w9WgXcQ")!)
        == "dQw4w9WgXcQ")

    // URLs with additional parameters
    #expect(
      YouTubeService.extractVideoID(
        from: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s")!) == "dQw4w9WgXcQ")
    #expect(
      YouTubeService.extractVideoID(
        from: URL(
          string:
            "https://www.youtube.com/watch?list=PLrAXtmRdnEQy6nuLMHjMZOz59Oq8VGLrG&v=dQw4w9WgXcQ")!)
        == "dQw4w9WgXcQ")

    // Invalid URLs should return nil
    #expect(YouTubeService.extractVideoID(from: URL(string: "https://www.google.com")!) == nil)
    #expect(YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/")!) == nil)
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/watch")!) == nil)
  }

  // MARK: - Thumbnail URL Tests

  @Test func testGetThumbnailURL() throws {
    let videoId = "dQw4w9WgXcQ"

    // Test different quality levels
    let defaultURL = YouTubeService.getThumbnailURL(for: videoId, quality: .default)
    #expect(defaultURL?.absoluteString == "https://img.youtube.com/vi/dQw4w9WgXcQ/default.jpg")

    let mediumURL = YouTubeService.getThumbnailURL(for: videoId, quality: .medium)
    #expect(mediumURL?.absoluteString == "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg")

    let highURL = YouTubeService.getThumbnailURL(for: videoId, quality: .high)
    #expect(highURL?.absoluteString == "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")

    let standardURL = YouTubeService.getThumbnailURL(for: videoId, quality: .standard)
    #expect(standardURL?.absoluteString == "https://img.youtube.com/vi/dQw4w9WgXcQ/sddefault.jpg")

    let maxResURL = YouTubeService.getThumbnailURL(for: videoId, quality: .maxRes)
    #expect(maxResURL?.absoluteString == "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
  }

  // MARK: - Video Metadata Tests

  @Test func testVideoMetadataInitialization() throws {
    let thumbnailURL = URL(string: "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
    let metadata = YouTubeService.VideoMetadata(
      videoId: "dQw4w9WgXcQ",
      title: "Test Video",
      author: "Test Channel",
      thumbnailURL: thumbnailURL,
      duration: "PT4M33S",
      description: "Test Description"
    )

    #expect(metadata.videoId == "dQw4w9WgXcQ")
    #expect(metadata.title == "Test Video")
    #expect(metadata.author == "Test Channel")
    #expect(metadata.thumbnailURL == thumbnailURL)
    #expect(metadata.duration == "PT4M33S")
    #expect(metadata.description == "Test Description")
  }

  // MARK: - Service Initialization Tests

  @Test func testYouTubeServiceInitialization() throws {
    let service = YouTubeService()

    // Service should initialize without issues
    #expect(service != nil)
  }

  // MARK: - Edge Cases

  @Test func testEdgeCases() throws {
    // Empty video ID
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/watch?v=")!) == nil)

    // Very short video ID (YouTube IDs are typically 11 characters)
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/watch?v=a")!) == "a")

    // Video ID with special characters (should still work)
    #expect(
      YouTubeService.extractVideoID(
        from: URL(string: "https://www.youtube.com/watch?v=abc-123_XYZ")!) == "abc-123_XYZ")

    // Case sensitivity
    #expect(
      YouTubeService.extractVideoID(from: URL(string: "https://www.youtube.com/watch?v=AbC123xyz")!)
        == "AbC123xyz")
  }

  // MARK: - URL Validation Edge Cases

  @Test func testURLValidationEdgeCases() throws {
    // Different protocols
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "http://www.youtube.com/watch?v=dQw4w9WgXcQ")!)
        == true)
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "ftp://www.youtube.com/watch?v=dQw4w9WgXcQ")!)
        == false)

    // Different subdomains
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://music.youtube.com/watch?v=dQw4w9WgXcQ")!)
        == true)
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://gaming.youtube.com/watch?v=dQw4w9WgXcQ")!)
        == true)

    // Case insensitive domain
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://YOUTUBE.COM/watch?v=dQw4w9WgXcQ")!) == true)
    #expect(
      YouTubeService.isYouTubeURL(URL(string: "https://YouTube.com/watch?v=dQw4w9WgXcQ")!) == true)
  }
}
