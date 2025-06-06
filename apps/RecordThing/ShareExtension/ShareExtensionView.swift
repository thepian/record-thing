//
//  ShareExtensionView.swift
//  ShareExtension
//
//  Created by Henrik Vendelbo on 07.02.2025.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI
import os.log
import RecordLib

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

struct ShareExtensionView: View {
    @StateObject private var contentViewModel = SharedContentViewModel()
    @State private var note: String = ""
    @State private var isLoading = false

    let onSave: (String) -> Void
    let onCancel: () -> Void
    let onContentUpdate: (SharedContentViewModel) -> Void
    
    // Logger following cursor rules
    private let logger = Logger(subsystem: "com.thepia.recordthing", category: "shareextension-ui")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCancel()
                    }

                // Main content card
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Send to RecordThing")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Add this content to your collection")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            logger.info("User tapped cancel button")
                            onCancel()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.systemBackground)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Content preview with hero image
                            if let content = contentViewModel.content {
                                SharedContentPreview(content: content)
                            } else if contentViewModel.isLoading {
                                LoadingContentPreview()
                            } else {
                                PlaceholderContentPreview()
                            }

                            // Note input with embedded send button
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add a note (optional)")
                                    .font(.headline)

                                // Adaptive layout based on screen size
                                if geometry.size.width > 600 {
                                    // iPad/larger screens: side-by-side layout
                                    HStack(alignment: .bottom, spacing: 12) {
                                        TextEditorWithButton(
                                            text: $note,
                                            placeholder: "What's this about?",
                                            isLoading: isLoading,
                                                                                onSend: {
                                        logger.info("User initiated send action (iPad layout) with note length: \(note.count)")
                                        isLoading = true
                                        onSave(note)
                                    }
                                        )
                                        .frame(minHeight: 100)
                                    }
                                } else {
                                    // iPhone: embedded button layout
                                    TextEditorWithButton(
                                        text: $note,
                                        placeholder: "What's this about?",
                                        isLoading: isLoading,
                                        onSend: {
                                            logger.info("User initiated send action (iPhone layout) with note length: \(note.count)")
                                            isLoading = true
                                            onSave(note)
                                        }
                                    )
                                    .frame(minHeight: 100)
                                }
                            }
                        }
                        .padding()
                    }


                }
                .background(Color.systemBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(geometry.size.width > 600 ? 40 : 20) // Larger padding on iPad
                .frame(maxWidth: geometry.size.width > 600 ? 500 : .infinity) // Limit width on iPad
                .frame(maxHeight: geometry.size.height * 0.8) // Don't take full screen
            }
        }
        .background(Color.clear) // Ensure transparent background
        .onAppear {
            logger.info("ShareExtensionView appeared, initializing content")
            onContentUpdate(contentViewModel)
        }
    }
}

// MARK: - Text Input Components

struct TextEditorWithButton: View {
    @Binding var text: String
    let placeholder: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Text editor background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.tertiarySystemBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondarySystemBackground, lineWidth: 1)
                )
            
            // Text editor with placeholder
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isTextEditorFocused)
                    .padding(.top, 8)
                    .padding(.leading, 12)
                    .padding(.trailing, 100) // Space for larger send button
                    .padding(.bottom, 48) // Extra space to keep send button visible
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: 120) // Reduced max height to account for button
                
                // Placeholder text
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            
            // Send button embedded in bottom-right corner
            Button(action: onSend) {
                HStack(spacing: 6) {
                    Text("Send")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: isLoading ? "hourglass" : "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                              Color.secondary : Color.red)
                )
            }
            .disabled(isLoading || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.trailing, 8)
            .padding(.bottom, 8)
        }
        .frame(minHeight: 100, maxHeight: 130) // Set bounds for the entire component
    }
}

// MARK: - Content Preview Components

struct SharedContentPreview: View {
    let content: SharedContent

    var body: some View {
        VStack(spacing: 0) {
                // Hero image
                if let heroImage = content.heroImage {
                    heroImage.asImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                } else if let placeholderImage = content.placeholderHeroImage {
                    placeholderImage.asImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8, corners: [.topLeft, .topRight])
                }

                // Content info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: content.contentType.icon)
                            .foregroundColor(content.contentType.color)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(content.displayTitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)

                            if let subtitle = content.displaySubtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Text(content.contentType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(content.contentType.color.opacity(0.1))
                            .foregroundColor(content.contentType.color)
                            .cornerRadius(4)
                    }
                }
                .padding()
                .background(Color.tertiarySystemBackground)
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondarySystemBackground, lineWidth: 1)
            )
    }
}

struct LoadingContentPreview: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
                .fill(Color.tertiarySystemBackground)
                .frame(height: 120)
                .overlay(
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading content...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                )
    }
}

struct PlaceholderContentPreview: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
                .fill(Color.tertiarySystemBackground)
                .frame(height: 120)
                .overlay(
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                            .font(.title2)
                        Text("Shared content will appear here")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding()
                )
    }
}

// MARK: - Helper Extensions

// Corner radius functionality is now provided by RecordLib

#if DEBUG
#Preview {
    ShareExtensionView(
        onSave: { note in
            print("Save with note: \(note)")
        },
        onCancel: {
            print("Cancel")
        },
        onContentUpdate: { viewModel in
            // Simulate content for preview
            let sampleContent = SharedContent(
                url: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
                title: "Sample YouTube Video",
                text: Optional<String>.none,
                image: Optional<RecordImage>.none,
                contentType: .youTubeVideo(videoId: "dQw4w9WgXcQ")
            )
            viewModel.updateContent(sampleContent)
        }
    )
}
#endif
