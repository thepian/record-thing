//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Henrik Vendelbo on 05.06.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import UIKit
import Social
import UniformTypeIdentifiers
import os

class ShareViewController: SLComposeServiceViewController {

    private let logger = Logger(subsystem: "com.thepia.recordthing.shareextension", category: "ShareViewController")

    override func viewDidLoad() {
        super.viewDidLoad()

        logger.info("🚀 ShareExtension viewDidLoad - Extension is active!")
        logger.info("📱 Extension bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        // Log host app info if available
        if let hostAppBundleID = Bundle.main.object(forInfoDictionaryKey: "NSExtensionHostApplicationBundleIdentifier") as? String {
            logger.info("📱 Host app bundle ID: \(hostAppBundleID)")
        } else {
            logger.info("📱 Host app bundle ID: unknown")
        }

        // Set up the UI
        self.title = "Save to RecordThing"
        self.placeholder = "Add a note about this content..."

        // Log extension context info
        logExtensionContext()

        // Extract and log shared content immediately
        extractSharedContent()
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

    override func isContentValid() -> Bool {
        // Always return true for minimal implementation
        return true
    }

    override func didSelectPost() {
        logger.info("User tapped Post button")

        // Log the user's comment if any
        if let comment = contentText, !comment.isEmpty {
            logger.info("User comment: \(comment)")
        }

        // Process the shared content
        processSharedContent()

        // Complete the extension
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // No configuration items for minimal implementation
        return []
    }

    // MARK: - Content Processing

    private func extractSharedContent() {
        logger.info("Starting content extraction...")

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            logger.error("No extension item found")
            return
        }

        logger.info("Extension item title: \(extensionItem.attributedTitle?.string ?? "No title")")
        logger.info("Extension item content text: \(extensionItem.attributedContentText?.string ?? "No content text")")

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

            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
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

            attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] (item, error) in
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

            attachment.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { [weak self] (item, error) in
                if let error = error {
                    self?.logger.error("Error loading property list: \(error.localizedDescription)")
                    return
                }

                if let dictionary = item as? [String: Any] {
                    self?.handleWebPageData(dictionary)
                }
            }
        }
        else {
            logger.info("Attachment \(index + 1): Unknown content type")
            // Log all available type identifiers for debugging
            for typeIdentifier in attachment.registeredTypeIdentifiers {
                logger.info("  Available type: \(typeIdentifier)")
            }
        }
    }

    private func handleURL(_ url: URL) {
        logger.info("📱 Received URL: \(url.absoluteString)")
        logger.info("   Scheme: \(url.scheme ?? "none")")
        logger.info("   Host: \(url.host ?? "none")")
        logger.info("   Path: \(url.path)")
        logger.info("   Query: \(url.query ?? "none")")
        logger.info("   Fragment: \(url.fragment ?? "none")")

        // Check if it's a YouTube URL
        if isYouTubeURL(url) {
            logger.info("🎥 YOUTUBE VIDEO DETECTED!")
            logger.info("   ✅ This is exactly what we want to capture!")

            // Extract video ID if possible
            if let videoID = extractYouTubeVideoID(from: url) {
                logger.info("   🆔 Video ID: \(videoID)")
                logger.info("   🔗 Full YouTube URL: https://www.youtube.com/watch?v=\(videoID)")
            } else {
                logger.warning("   ⚠️ Could not extract video ID from YouTube URL")
            }

            // Log success for debugging
            logger.info("   🎯 ShareExtension successfully detected YouTube content!")
        } else {
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

    private func processSharedContent() {
        logger.info("🎯 Processing shared content for saving...")

        // TODO: Here you would implement actual saving to database
        // For now, just log that we're processing
        logger.info("✅ Content processing completed (logged only)")
    }

    // MARK: - YouTube Detection Helpers

    private func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }

        return host.contains("youtube.com") ||
               host.contains("youtu.be") ||
               host.contains("m.youtube.com") ||
               host.contains("www.youtube.com")
    }

    private func extractYouTubeVideoID(from url: URL) -> String? {
        // Handle youtu.be short URLs
        if url.host?.contains("youtu.be") == true {
            return String(url.path.dropFirst()) // Remove leading "/"
        }

        // Handle youtube.com URLs
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            return queryItems.first(where: { $0.name == "v" })?.value
        }

        return nil
    }

    private func extractURLFromText(_ text: String) -> URL? {
        // Simple URL detection in text
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        if let match = matches?.first, let url = match.url {
            return url
        }

        return nil
    }
}
