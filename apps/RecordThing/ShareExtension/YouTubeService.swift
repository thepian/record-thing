//
//  YouTubeService.swift
//  ShareExtension
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import Foundation
import os

#if os(iOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

/// Service for fetching YouTube video metadata and thumbnails
class YouTubeService {
  private let logger = Logger(
    subsystem: "com.thepia.recordthing.shareextension", category: "YouTubeService")

  /// YouTube video metadata
  struct VideoMetadata {
    let videoId: String
    let title: String?
    let author: String?
    let thumbnailURL: URL?
    let duration: String?
    let description: String?
  }

  /// Extract video ID from various YouTube URL formats
  static func extractVideoID(from url: URL) -> String? {
    let urlString = url.absoluteString.lowercased()

    // Handle youtu.be short URLs
    if url.host?.contains("youtu.be") == true {
      return String(url.path.dropFirst())  // Remove leading "/"
    }

    // Handle youtube.com URLs
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems
    {

      // Standard watch URLs: youtube.com/watch?v=VIDEO_ID
      if let videoId = queryItems.first(where: { $0.name == "v" })?.value {
        return videoId
      }
    }

    // Handle embed URLs: youtube.com/embed/VIDEO_ID
    if urlString.contains("/embed/") {
      let components = url.pathComponents
      if let embedIndex = components.firstIndex(of: "embed"),
        embedIndex + 1 < components.count
      {
        return components[embedIndex + 1]
      }
    }

    // Handle YouTube app URLs and other formats
    if urlString.contains("youtube.com/") || urlString.contains("m.youtube.com/") {
      // Try to extract from path components
      let pathComponents = url.pathComponents
      for (index, component) in pathComponents.enumerated() {
        if component == "watch" && index + 1 < pathComponents.count {
          // Sometimes the video ID is in the path
          let nextComponent = pathComponents[index + 1]
          if nextComponent.count == 11 {  // YouTube video IDs are 11 characters
            return nextComponent
          }
        }
      }
    }

    return nil
  }

  /// Check if URL is a YouTube URL (supports all formats)
  static func isYouTubeURL(_ url: URL) -> Bool {
    guard let host = url.host?.lowercased() else { return false }

    return host.contains("youtube.com") || host.contains("youtu.be")
      || host.contains("m.youtube.com") || host.contains("www.youtube.com")
      || host.contains("music.youtube.com")
  }

  /// Fetch video metadata using oEmbed API (no API key required)
  func fetchVideoMetadata(for videoId: String) async -> VideoMetadata? {
    let youtubeURL = "https://www.youtube.com/watch?v=\(videoId)"
    let oembedURL = "https://www.youtube.com/oembed?url=\(youtubeURL)&format=json"

    guard let url = URL(string: oembedURL) else {
      logger.error("Invalid oEmbed URL")
      return nil
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        logger.error("oEmbed API request failed")
        return nil
      }

      let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

      let title = json?["title"] as? String
      let author = json?["author_name"] as? String
      let thumbnailURLString = json?["thumbnail_url"] as? String
      let thumbnailURL = thumbnailURLString.flatMap { URL(string: $0) }

      logger.info("✅ Fetched YouTube metadata: \(title ?? "No title")")

      return VideoMetadata(
        videoId: videoId,
        title: title,
        author: author,
        thumbnailURL: thumbnailURL,
        duration: nil,
        description: nil
      )

    } catch {
      logger.error("Failed to fetch YouTube metadata: \(error.localizedDescription)")
      return nil
    }
  }

  /// Get thumbnail URL for video ID (multiple quality options)
  static func getThumbnailURL(for videoId: String, quality: ThumbnailQuality = .high) -> URL? {
    let baseURL = "https://img.youtube.com/vi/\(videoId)"

    switch quality {
    case .maxRes:
      return URL(string: "\(baseURL)/maxresdefault.jpg")
    case .high:
      return URL(string: "\(baseURL)/hqdefault.jpg")
    case .medium:
      return URL(string: "\(baseURL)/mqdefault.jpg")
    case .standard:
      return URL(string: "\(baseURL)/sddefault.jpg")
    case .default:
      return URL(string: "\(baseURL)/default.jpg")
    }
  }

  /// Fetch thumbnail image
  #if os(iOS)
    func fetchThumbnail(for videoId: String, quality: ThumbnailQuality = .high) async -> UIImage? {
      // Try multiple quality levels in case higher quality isn't available
      let qualities: [ThumbnailQuality] = [quality, .high, .medium, .standard, .default]

      for thumbnailQuality in qualities {
        guard let url = Self.getThumbnailURL(for: videoId, quality: thumbnailQuality) else {
          continue
        }

        do {
          let (data, response) = try await URLSession.shared.data(from: url)

          guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200,
            let image = UIImage(data: data)
          else {
            continue
          }

          logger.info("✅ Fetched YouTube thumbnail (\(thumbnailQuality.rawValue))")
          return image

        } catch {
          logger.warning(
            "Failed to fetch thumbnail at \(thumbnailQuality.rawValue) quality: \(error.localizedDescription)"
          )
          continue
        }
      }

      logger.error("Failed to fetch any YouTube thumbnail for video \(videoId)")
      return nil
    }
  #elseif os(macOS)
    func fetchThumbnail(for videoId: String, quality: ThumbnailQuality = .high) async -> NSImage? {
      // Try multiple quality levels in case higher quality isn't available
      let qualities: [ThumbnailQuality] = [quality, .high, .medium, .standard, .default]

      for thumbnailQuality in qualities {
        guard let url = Self.getThumbnailURL(for: videoId, quality: thumbnailQuality) else {
          continue
        }

        do {
          let (data, response) = try await URLSession.shared.data(from: url)

          guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200,
            let image = NSImage(data: data)
          else {
            continue
          }

          logger.info("✅ Fetched YouTube thumbnail (\(thumbnailQuality.rawValue))")
          return image

        } catch {
          logger.warning(
            "Failed to fetch thumbnail at \(thumbnailQuality.rawValue) quality: \(error.localizedDescription)"
          )
          continue
        }
      }

      logger.error("Failed to fetch any YouTube thumbnail for video \(videoId)")
      return nil
    }
  #endif

  enum ThumbnailQuality: String, CaseIterable {
    case maxRes = "maxresdefault"
    case high = "hqdefault"
    case medium = "mqdefault"
    case standard = "sddefault"
    case `default` = "default"

    var displayName: String {
      switch self {
      case .maxRes: return "Max Resolution"
      case .high: return "High Quality"
      case .medium: return "Medium Quality"
      case .standard: return "Standard Quality"
      case .default: return "Default"
      }
    }
  }
}
