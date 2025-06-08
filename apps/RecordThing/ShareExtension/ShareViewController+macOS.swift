//
//  ShareViewController+macOS.swift
//  ShareExtension
//
//  Created by Augment Agent on 2025-06-08.
//  Copyright © 2025 Thepia. All rights reserved.
//

#if os(macOS)
  import AppKit
  import RecordLib
  import SwiftUI
  import UniformTypeIdentifiers
  import os

  class ShareViewController: NSViewController {

    private let logger = Logger(
      subsystem: "com.thepia.recordthing.shareextension", category: "ShareViewController")
    private var contentViewModel: SharedContentViewModel?
    private let youtubeService = YouTubeService()
    private let datasource = ShareExtensionDatasource.shared

    override func viewDidLoad() {
      super.viewDidLoad()

      // Set transparent background
      view.wantsLayer = true
      view.layer?.backgroundColor = NSColor.clear.cgColor

      // Add logging for macOS
      print("🚀 SHAREEXTENSION (macOS): viewDidLoad - Extension is active!")
      print(
        "📱 SHAREEXTENSION (macOS): Extension bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")"
      )

      logger.info("🚀 ShareExtension (macOS) viewDidLoad - Extension is active!")
      logger.info("📱 Extension bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

      // Log host app info if available
      if let hostAppBundleID = Bundle.main.object(
        forInfoDictionaryKey: "NSExtensionHostApplicationBundleIdentifier") as? String
      {
        print("📱 SHAREEXTENSION (macOS): Host app bundle ID: \(hostAppBundleID)")
        logger.info("📱 Host app bundle ID: \(hostAppBundleID)")
      } else {
        print("📱 SHAREEXTENSION (macOS): Host app bundle ID: unknown")
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
      logger.info("🔧 Initializing ShareExtension (macOS) database connection...")

      Task {
        let isReady = await datasource.validateDatabaseAccess()
        await MainActor.run {
          if isReady {
            logger.info("✅ ShareExtension (macOS) database connection ready")
          } else {
            logger.error("❌ ShareExtension (macOS) database connection failed")
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

      // Wrap in NSHostingController
      let hostingController = NSHostingController(rootView: shareView)

      // Add as child view controller
      addChild(hostingController)
      view.addSubview(hostingController.view)

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
      print("💾 SHAREEXTENSION (macOS): User tapped Save button")
      logger.info("User tapped Save button")

      if !note.isEmpty {
        print("📝 SHAREEXTENSION (macOS): User note: \(note)")
        logger.info("User note: \(note)")
      }

      // Process the shared content asynchronously
      Task {
        await processSharedContent(with: note)

        await MainActor.run {
          print("✅ SHAREEXTENSION (macOS): Completing request")
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
          domain: "ShareExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
        ))
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

      // Extract URL (macOS version)
      for attachment in attachments {
        if attachment.hasItemConformingToTypeIdentifier("public.url") {
          do {
            let urlData = try await attachment.loadItem(
              forTypeIdentifier: "public.url", options: nil)
            if let url = urlData as? URL {
              extractedURL = url
              break
            }
          } catch {
            logger.error("Failed to extract URL: \(error.localizedDescription)")
          }
        }
      }

      // Extract text
      for attachment in attachments {
        if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
          do {
            let textData = try await attachment.loadItem(
              forTypeIdentifier: "public.plain-text", options: nil)
            if let text = textData as? String {
              extractedText = text
              break
            }
          } catch {
            logger.error("Failed to extract text: \(error.localizedDescription)")
          }
        }
      }

      // Determine content type and fetch enhanced data
      let contentType: SharedContent.ContentType
      if let url = extractedURL {
        if YouTubeService.isYouTubeURL(url), let videoId = YouTubeService.extractVideoID(from: url)
        {
          contentType = .youTubeVideo(videoId: videoId)

          // Fetch YouTube metadata and thumbnail
          if let metadata = await youtubeService.fetchVideoMetadata(for: videoId) {
            extractedTitle = metadata.title
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
        title: extractedTitle ?? "Shared Content",
        text: extractedText,
        image: nil,  // macOS doesn't need image extraction for now
        contentType: contentType
      )
    }

    private func extractionContext(from url: URL) -> String {
      return url.host ?? url.absoluteString
    }

    private func logExtensionContext() {
      guard let extensionContext = extensionContext else {
        logger.info("❌ No extension context available")
        return
      }

      logger.info(
        "📋 Extension context available with \(extensionContext.inputItems.count) input items")

      for (index, item) in extensionContext.inputItems.enumerated() {
        if let extensionItem = item as? NSExtensionItem {
          logger.info("📄 Item \(index): \(extensionItem.attachments?.count ?? 0) attachments")
        }
      }
    }

    private func extractSharedContent() {
      Task {
        if let content = await extractSharedContentForDisplay() {
          logger.info("📥 Extracted shared content: \(content.title ?? "No title")")
          if let url = content.url {
            logger.info("🔗 URL: \(url.absoluteString)")
          }
        } else {
          logger.error("❌ Failed to extract shared content")
        }
      }
    }

    private func processSharedContent(with note: String) async {
      logger.info("🔄 Processing shared content with note: \(note)")

      // TODO: Implement actual database saving
      // For now, just log the content
      if let content = await extractSharedContentForDisplay() {
        logger.info("💾 Would save content: \(content.title ?? "No title")")
        if let url = content.url {
          logger.info("🔗 URL: \(url.absoluteString)")
        }
        logger.info("📝 Note: \(note)")
      }
    }
  }

#endif
