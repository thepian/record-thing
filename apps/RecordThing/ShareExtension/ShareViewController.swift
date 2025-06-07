//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Henrik Vendelbo on 05.06.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import RecordLib
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import os

class ShareViewController: UIViewController {

  private let logger = Logger(
    subsystem: "com.thepia.recordthing.shareextension", category: "ShareViewController")
  private var contentViewModel: SharedContentViewModel?
  private let youtubeService = YouTubeService()
  private let datasource = ShareExtensionDatasource.shared

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set transparent background to avoid grey background
    view.backgroundColor = UIColor.clear

    // Add print statements that will definitely appear in system logs
    print("🚀 SHAREEXTENSION: viewDidLoad - Extension is active!")
    print("📱 SHAREEXTENSION: Extension bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

    logger.info("🚀 ShareExtension viewDidLoad - Extension is active!")
    logger.info("📱 Extension bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

    // Log host app info if available
    if let hostAppBundleID = Bundle.main.object(
      forInfoDictionaryKey: "NSExtensionHostApplicationBundleIdentifier") as? String
    {
      print("📱 SHAREEXTENSION: Host app bundle ID: \(hostAppBundleID)")
      logger.info("📱 Host app bundle ID: \(hostAppBundleID)")
    } else {
      print("📱 SHAREEXTENSION: Host app bundle ID: unknown")
      logger.info("📱 Host app bundle ID: unknown")
    }

    // Initialize database connection
    initializeDatabaseConnection()

    // Set up SwiftUI interface
    setupSwiftUIInterface()

    // Log extension context info
    logExtensionContext()

    // Extract and log shared content immediately
    extractSharedContent()
  }

  private func initializeDatabaseConnection() {
    logger.info("🔧 Initializing ShareExtension database connection...")

    Task {
      let isReady = await datasource.validateDatabaseAccess()
      await MainActor.run {
        if isReady {
          logger.info("✅ ShareExtension database connection ready")
        } else {
          logger.error("❌ ShareExtension database connection failed")
        }
      }
    }
  }

  private func setupSwiftUIInterface() {
    // Create SwiftUI view
    let shareView = ShareExtensionView(
      onSave: { [weak self] note in
        self?.handleSave(with: note)
      },
      onCancel: { [weak self] in
        self?.handleCancel()
      },
      onContentUpdate: { [weak self] viewModel in
        self?.contentViewModel = viewModel
        self?.updateContentViewModel()
      }
    )
    .environment(\.shareExtensionDatasource, datasource)

    // Wrap in UIHostingController
    let hostingController = UIHostingController(rootView: shareView)

    // Set transparent background for hosting controller
    hostingController.view.backgroundColor = UIColor.clear

    // Add as child view controller
    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)

    // Set up constraints
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func handleSave(with note: String) {
    print("💾 SHAREEXTENSION: User tapped Save button")
    logger.info("User tapped Save button")

    if !note.isEmpty {
      print("📝 SHAREEXTENSION: User note: \(note)")
      logger.info("User note: \(note)")
    }

    // Process the shared content asynchronously
    Task {
      await processSharedContent(with: note)

      await MainActor.run {
        print("✅ SHAREEXTENSION: Completing request")
        // Complete the extension
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
      }
    }
  }

  private func handleCancel() {
    logger.info("User tapped Cancel button")

    // Cancel the extension
    extensionContext?.cancelRequest(
      withError: NSError(
        domain: "ShareExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
  }

  private func updateContentViewModel() {
    guard let viewModel = contentViewModel else { return }

    Task { @MainActor in
      viewModel.setLoading(true)

      // Extract content from extension context
      if let sharedContent = await extractSharedContentForDisplay() {
        viewModel.updateContent(sharedContent)
      } else {
        viewModel.setError("Could not load shared content")
      }

      viewModel.setLoading(false)
    }
  }

  private func extractSharedContentForDisplay() async -> SharedContent? {
    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
      let attachments = extensionItem.attachments
    else {
      return nil
    }

    var extractedURL: URL?
    var extractedTitle: String?
    var extractedText: String?
    var extractedImage: UIImage?

    // Extract URL
    for attachment in attachments {
      if attachment.hasItemConformingToTypeIdentifier("public.url") {
        do {
          let urlData = try await attachment.loadItem(forTypeIdentifier: "public.url", options: nil)
          if let url = urlData as? URL {
            extractedURL = url
            break
          }
        } catch {
          logger.error("Failed to extract URL: \(error.localizedDescription)")
        }
      }
    }

    // Extract text if no URL found
    if extractedURL == nil {
      for attachment in attachments {
        if attachment.hasItemConformingToTypeIdentifier("public.text") {
          do {
            let textData = try await attachment.loadItem(
              forTypeIdentifier: "public.text", options: nil)
            if let text = textData as? String {
              extractedText = text
              // Try to extract URL from text
              if let urlFromText = extractURLFromText(text) {
                extractedURL = urlFromText
              }
              break
            }
          } catch {
            logger.error("Failed to extract text: \(error.localizedDescription)")
          }
        }
      }
    }

    // Determine content type and fetch enhanced data
    let contentType: SharedContent.ContentType
    if let url = extractedURL {
      if YouTubeService.isYouTubeURL(url), let videoId = YouTubeService.extractVideoID(from: url) {
        contentType = .youTubeVideo(videoId: videoId)

        // Fetch YouTube metadata and thumbnail
        if let metadata = await youtubeService.fetchVideoMetadata(for: videoId) {
          extractedTitle = metadata.title
        }

        if let thumbnail = await youtubeService.fetchThumbnail(for: videoId, quality: .high) {
          extractedImage = thumbnail
        }
      } else {
        contentType = .webPage
        extractedTitle = extractionContext(from: url)
      }
    } else if extractedText != nil {
      contentType = .text
    } else {
      contentType = .unknown
    }

    return SharedContent(
      url: extractedURL,
      title: extractedTitle,
      text: extractedText,
      image: extractedImage,
      contentType: contentType
    )
  }

  private func extractionContext(from url: URL) -> String? {
    // For YouTube, try to get a better title
    if YouTubeService.isYouTubeURL(url) {
      return "YouTube Video"
    }

    // For other URLs, use the host
    return url.host
  }

  private func extractURLFromText(_ text: String) -> URL? {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detector?.matches(
      in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

    return matches?.first?.url
  }

  private func logExtensionContext() {
    guard let context = extensionContext else {
      logger.error("❌ No extension context available")
      return
    }

    logger.info("📋 Extension context available")
    logger.info("📊 Input items count: \(context.inputItems.count)")

    for (index, item) in context.inputItems.enumerated() {
      if let extensionItem = item as? NSExtensionItem {
        logger.info("📄 Item \(index + 1):")
        logger.info("   Title: \(extensionItem.attributedTitle?.string ?? "No title")")
        logger.info("   Content: \(extensionItem.attributedContentText?.string ?? "No content")")
        logger.info("   Attachments: \(extensionItem.attachments?.count ?? 0)")

        if let attachments = extensionItem.attachments {
          for (attachIndex, attachment) in attachments.enumerated() {
            logger.info("   Attachment \(attachIndex + 1): \(attachment.registeredTypeIdentifiers)")
          }
        }
      }
    }
  }

  // MARK: - Content Processing

  private func extractSharedContent() {
    logger.info("Starting content extraction...")

    guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
      logger.error("No extension item found")
      return
    }

    logger.info("Extension item title: \(extensionItem.attributedTitle?.string ?? "No title")")
    logger.info(
      "Extension item content text: \(extensionItem.attributedContentText?.string ?? "No content text")"
    )

    guard let attachments = extensionItem.attachments else {
      logger.error("No attachments found")
      return
    }

    logger.info("Found \(attachments.count) attachment(s)")

    // Process each attachment
    for (index, attachment) in attachments.enumerated() {
      logger.info("Processing attachment \(index + 1)")
      processAttachment(attachment, index: index)
    }
  }

  private func processAttachment(_ attachment: NSItemProvider, index: Int) {
    // Check for URL content
    if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      logger.info("Attachment \(index + 1): Found URL content")

      attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) {
        [weak self] (item, error) in
        if let error = error {
          self?.logger.error("Error loading URL: \(error.localizedDescription)")
          return
        }

        if let url = item as? URL {
          self?.handleURL(url)
        }
      }
    }
    // Check for text content
    else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
      logger.info("Attachment \(index + 1): Found text content")

      attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) {
        [weak self] (item, error) in
        if let error = error {
          self?.logger.error("Error loading text: \(error.localizedDescription)")
          return
        }

        if let text = item as? String {
          self?.handleText(text)
        }
      }
    }
    // Check for web page content
    else if attachment.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
      logger.info("Attachment \(index + 1): Found property list content (likely web page)")

      attachment.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) {
        [weak self] (item, error) in
        if let error = error {
          self?.logger.error("Error loading property list: \(error.localizedDescription)")
          return
        }

        if let dictionary = item as? [String: Any] {
          self?.handleWebPageData(dictionary)
        }
      }
    } else {
      logger.info("Attachment \(index + 1): Unknown content type")
      // Log all available type identifiers for debugging
      for typeIdentifier in attachment.registeredTypeIdentifiers {
        logger.info("  Available type: \(typeIdentifier)")
      }
    }
  }

  private func handleURL(_ url: URL) {
    // Add print statements for system logs
    print("📱 SHAREEXTENSION: Received URL: \(url.absoluteString)")
    print("   SHAREEXTENSION: Host: \(url.host ?? "none")")

    logger.info("📱 Received URL: \(url.absoluteString)")
    logger.info("   Scheme: \(url.scheme ?? "none")")
    logger.info("   Host: \(url.host ?? "none")")
    logger.info("   Path: \(url.path)")
    logger.info("   Query: \(url.query ?? "none")")
    logger.info("   Fragment: \(url.fragment ?? "none")")

    // Check if it's a YouTube URL
    if YouTubeService.isYouTubeURL(url) {
      print("🎥 SHAREEXTENSION: YOUTUBE VIDEO DETECTED!")
      logger.info("🎥 YOUTUBE VIDEO DETECTED!")
      logger.info("   ✅ This is exactly what we want to capture!")

      // Extract video ID if possible
      if let videoID = YouTubeService.extractVideoID(from: url) {
        print("   🆔 SHAREEXTENSION: Video ID: \(videoID)")
        logger.info("   🆔 Video ID: \(videoID)")
        logger.info("   🔗 Full YouTube URL: https://www.youtube.com/watch?v=\(videoID)")
      } else {
        print("   ⚠️ SHAREEXTENSION: Could not extract video ID")
        logger.warning("   ⚠️ Could not extract video ID from YouTube URL")
      }

      print("   🎯 SHAREEXTENSION: Successfully detected YouTube content!")
      logger.info("   🎯 ShareExtension successfully detected YouTube content!")
    } else {
      print("🌐 SHAREEXTENSION: Regular web URL detected")
      logger.info("🌐 Regular web URL detected")
      logger.info("   📝 This will be saved as general web content")
    }
  }

  private func handleText(_ text: String) {
    logger.info("📝 Received text: \(text)")

    // Check if text contains a URL
    if let url = extractURLFromText(text) {
      logger.info("   Found URL in text: \(url.absoluteString)")
      handleURL(url)
    }
  }

  private func handleWebPageData(_ data: [String: Any]) {
    logger.info("🌐 Received web page data:")

    for (key, value) in data {
      logger.info("   \(key): \(String(describing: value))")
    }

    // Look for URL in the data
    if let urlString = data["URL"] as? String, let url = URL(string: urlString) {
      handleURL(url)
    }
  }

  private func processSharedContent(with note: String) async {
    logger.info("🎯 Processing shared content for saving...")

    // Extract the shared content
    guard let sharedContent = await extractSharedContentForDisplay() else {
      logger.error("❌ Failed to extract shared content for saving")
      return
    }

    logger.info("💾 Saving shared content: \(sharedContent.contentType.displayName)")

    // Save to database using the datasource
    let success = await datasource.saveSharedContent(sharedContent, note: note)

    if success {
      logger.info("✅ Successfully saved shared content to database")
      print("✅ SHAREEXTENSION: Content saved to database!")
    } else {
      logger.error("❌ Failed to save shared content to database")
      print("❌ SHAREEXTENSION: Failed to save content!")

      // Fallback: Create unprocessed share for main app to handle
      logger.info("🔄 Creating unprocessed share as fallback...")
      let fallbackSuccess = await datasource.createUnprocessedShare(sharedContent, note: note)

      if fallbackSuccess {
        logger.info("✅ Created unprocessed share for main app to process")
        print("✅ SHAREEXTENSION: Created unprocessed share!")
      } else {
        logger.error("❌ Failed to create unprocessed share")
        print("❌ SHAREEXTENSION: Complete failure to save!")
      }
    }
  }

  // MARK: - Helper Methods

}
