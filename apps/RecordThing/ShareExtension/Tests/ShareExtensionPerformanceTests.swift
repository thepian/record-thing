//
//  ShareExtensionPerformanceTests.swift
//  ShareExtensionTests
//
//  Created by AI Assistant on 06.06.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Testing
import Foundation
@testable import ShareExtension

struct ShareExtensionPerformanceTests {
    
    // MARK: - URL Processing Performance Tests
    
    @Test func testYouTubeURLRecognitionPerformance() async throws {
        let urls = TestConfiguration.sampleYouTubeURLs.compactMap { URL(string: $0) }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test recognition performance for 1000 iterations
        for _ in 0..<1000 {
            for url in urls {
                _ = YouTubeService.isYouTubeURL(url)
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 1000 iterations of 8 URLs (8000 operations) in under 1 second
        #expect(timeElapsed < 1.0, "YouTube URL recognition should be fast: \(timeElapsed)s for 8000 operations")
    }
    
    @Test func testVideoIDExtractionPerformance() async throws {
        let urls = TestConfiguration.sampleYouTubeURLs.compactMap { URL(string: $0) }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test extraction performance for 1000 iterations
        for _ in 0..<1000 {
            for url in urls {
                _ = YouTubeService.extractVideoID(from: url)
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 1000 iterations of 8 URLs (8000 operations) in under 1 second
        #expect(timeElapsed < 1.0, "Video ID extraction should be fast: \(timeElapsed)s for 8000 operations")
    }
    
    @Test func testThumbnailURLGenerationPerformance() async throws {
        let videoIds = TestConfiguration.sampleVideoIds
        let qualities: [YouTubeService.ThumbnailQuality] = [.default, .medium, .high, .standard, .maxRes]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test thumbnail URL generation for 1000 iterations
        for _ in 0..<1000 {
            for videoId in videoIds {
                for quality in qualities {
                    _ = YouTubeService.thumbnailURL(for: videoId, quality: quality)
                }
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 1000 iterations of 5 video IDs × 5 qualities (25000 operations) in under 1 second
        #expect(timeElapsed < 1.0, "Thumbnail URL generation should be fast: \(timeElapsed)s for 25000 operations")
    }
    
    // MARK: - SharedContent Performance Tests
    
    @Test func testSharedContentCreationPerformance() async throws {
        let urls = TestConfiguration.sampleYouTubeURLs.compactMap { URL(string: $0) }
        let titles = TestConfiguration.sampleTitles
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test SharedContent creation for 1000 iterations
        for i in 0..<1000 {
            let url = urls[i % urls.count]
            let title = titles[i % titles.count]
            let videoId = YouTubeService.extractVideoID(from: url) ?? "unknown"
            
            _ = SharedContent(
                url: url,
                title: title,
                text: nil,
                image: nil,
                contentType: .youTubeVideo(videoId: videoId)
            )
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 1000 SharedContent creations in under 0.1 seconds
        #expect(timeElapsed < 0.1, "SharedContent creation should be fast: \(timeElapsed)s for 1000 operations")
    }
    
    @Test func testDisplayTitleGenerationPerformance() async throws {
        let contents = (0..<1000).map { i in
            TestConfiguration.createYouTubeContent(
                videoId: "test\(i)",
                title: "Test Video \(i)"
            )
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test display title generation
        for content in contents {
            _ = content.displayTitle
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 1000 display title generations in under 0.05 seconds
        #expect(timeElapsed < 0.05, "Display title generation should be fast: \(timeElapsed)s for 1000 operations")
    }
    
    // MARK: - ViewModel Performance Tests
    
    @Test func testViewModelUpdatePerformance() async throws {
        let viewModel = SharedContentViewModel()
        let contents = (0..<100).map { i in
            TestConfiguration.createYouTubeContent(
                videoId: "test\(i)",
                title: "Test Video \(i)"
            )
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test rapid content updates
        for content in contents {
            viewModel.updateContent(content)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 100 view model updates in under 0.01 seconds
        #expect(timeElapsed < 0.01, "ViewModel updates should be fast: \(timeElapsed)s for 100 operations")
    }
    
    @Test func testViewModelStateChangesPerformance() async throws {
        let viewModel = SharedContentViewModel()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test rapid state changes
        for i in 0..<1000 {
            if i % 3 == 0 {
                viewModel.setLoading(true)
            } else if i % 3 == 1 {
                viewModel.setError("Error \(i)")
            } else {
                let content = TestConfiguration.createYouTubeContent(videoId: "test\(i)")
                viewModel.updateContent(content)
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete 1000 state changes in under 0.1 seconds
        #expect(timeElapsed < 0.1, "ViewModel state changes should be fast: \(timeElapsed)s for 1000 operations")
    }
    
    // MARK: - Memory Performance Tests
    
    @Test func testMemoryUsageWithManyContents() async throws {
        var contents: [SharedContent] = []
        
        // Create many SharedContent objects
        for i in 0..<10000 {
            let content = TestConfiguration.createYouTubeContent(
                videoId: "test\(i)",
                title: "Test Video \(i)"
            )
            contents.append(content)
        }
        
        // Verify we can access all contents quickly
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var titleCount = 0
        for content in contents {
            if !content.displayTitle.isEmpty {
                titleCount += 1
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(titleCount == 10000)
        #expect(timeElapsed < 0.1, "Processing 10000 contents should be fast: \(timeElapsed)s")
        
        // Clean up
        contents.removeAll()
    }
    
    // MARK: - Concurrent Access Performance Tests
    
    @Test func testConcurrentURLProcessing() async throws {
        let urls = TestConfiguration.sampleYouTubeURLs.compactMap { URL(string: $0) }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test concurrent URL processing
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    for url in urls {
                        _ = YouTubeService.isYouTubeURL(url)
                        _ = YouTubeService.extractVideoID(from: url)
                    }
                }
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete concurrent processing in under 1 second
        #expect(timeElapsed < 1.0, "Concurrent URL processing should be fast: \(timeElapsed)s")
    }
    
    @Test func testConcurrentViewModelUpdates() async throws {
        let viewModel = SharedContentViewModel()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test concurrent view model updates (should be thread-safe)
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let content = TestConfiguration.createYouTubeContent(
                        videoId: "test\(i)",
                        title: "Test Video \(i)"
                    )
                    await MainActor.run {
                        viewModel.updateContent(content)
                    }
                }
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete concurrent updates in under 0.5 seconds
        #expect(timeElapsed < 0.5, "Concurrent ViewModel updates should be fast: \(timeElapsed)s")
    }
}
