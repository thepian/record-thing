import SwiftUI
import os

/// A component that displays a small stack of images in a fanned arrangement, similar to a hand of cards.
///
/// The `ImageCardStack` can display between 0 and 5 images in a visually appealing, overlapping arrangement.
/// When no images are provided, it displays a transparent circle as a placeholder.
///
/// Features:
/// - Displays up to 5 images in a fanned stack
/// - Customizable size, spacing, and rotation
/// - Optional border and shadow effects
/// - Fallback placeholder when no images are present
/// - Support for both system images and custom images
/// - Tap handling for the entire stack
/// - Animated replacement of the top card
///
/// Example usage:
/// ```swift
/// ImageCardStack(
///     viewModel: EvidenceViewModel(
///         cardImages: [
///             .system("photo"),
///             .system("camera"),
///             .system("doc.text.image")
///         ],
///         cardSize: 60,
///         cardSpacing: 12,
///         cardRotation: 4
///     )
/// )
/// ```
public struct ImageCardStack<Item: VisualRecording>: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.image-card-stack")
    
    // ViewModel
    @State var pieces: [Item]
    let designSystem: DesignSystemSetup
    
    // Animation state
    @State private var isAnimatingReplacement: Bool = false
    @State private var replacementImage: Item?
    @State private var replacementOffset: CGFloat = 50
    @State private var replacementOpacity: Double = 0
    @State private var topCardOffset: CGFloat = 0
    @State private var topCardOpacity: Double = 1
    
//    private let onTap: (() -> Void)?
    private let replacementAnimationDuration: Double
    
    // MARK: - Initialization
    
    /// Creates a new ImageCardStack
    ///   - replacementAnimationDuration: Duration of the card replacement animation
    ///   - onTap: Action to perform when the stack is tapped
    /// - Parameter viewModel: The view model that manages the state and business logic
    public init(
        pieces: [Item],
        designSystem: DesignSystemSetup,
        replacementAnimationDuration: Double = 0.5
    ) {
        self.pieces = pieces
        self.designSystem = designSystem
        self.replacementAnimationDuration = replacementAnimationDuration
        logger.trace("ImageCardStack initialized with view model")
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            if pieces.isEmpty {
                // Placeholder when no images are present
                emptyPlaceholder
            } else {
                // Fanned stack of images
                cardStack
                
                // Replacement card animation
                if isAnimatingReplacement, let replacement = replacementImage {
                    cardView(for: replacement)
                        .offset(x: xOffset(for: pieces.count - 1), y: replacementOffset)
                        .rotationEffect(.degrees(rotationAngle(for: pieces.count - 1)))
                        .opacity(replacementOpacity)
                        .zIndex(Double(pieces.count + 1))
                }
            }
        }
        .frame(width: stackWidth, height: designSystem.cardSize)
        .contentShape(Rectangle())
    }
    
    // MARK: - UI Components
    
    /// The fanned stack of cards
    private var cardStack: some View {
        ZStack {
            // Display cards from back to front
            ForEach(Array(pieces.enumerated()), id: \.element.id) { index, piece in
                if index == pieces.count - 1 && isAnimatingReplacement {
                    // Top card that's being replaced
                    cardView(for: piece)
                        .offset(x: xOffset(for: index), y: topCardOffset)
                        .rotationEffect(.degrees(rotationAngle(for: index)))
                        .opacity(topCardOpacity)
                        .zIndex(Double(index))
                } else {
                    // Regular cards
                    cardView(for: piece)
                        .offset(x: xOffset(for: index))
                        .rotationEffect(.degrees(rotationAngle(for: index)))
                        .zIndex(Double(index))
                }
            }
        }
    }
    
    /// A single card in the stack
    private func cardView(for piece: Item) -> some View {
        piece.image?
            .resizable()
            .scaledToFill()
            .frame(width: designSystem.cardSize, height: designSystem.cardSize)
            .clipShape(RoundedRectangle(cornerRadius: designSystem.cornerRadius))
            .overlay(
                Group {
                    if designSystem.showCardBorder {
                        RoundedRectangle(cornerRadius: designSystem.cornerRadius)
                            .stroke(designSystem.borderColor, lineWidth: designSystem.borderWidth)
                    }
                }
            )
            .shadow(color: designSystem.shadowColor, radius: designSystem.shadowRadius)
    }
    
    /// Placeholder shown when no images are present
    private var emptyPlaceholder: some View {
        ZStack {
            Circle()
                .fill(designSystem.placeholderColor)
                .frame(width: designSystem.cardSize, height: designSystem.cardSize)
                .overlay(
                    Group {
                        if designSystem.showCardBorder {
                            Circle()
                                .stroke(designSystem.borderColor, lineWidth: designSystem.borderWidth)
                        }
                    }
                )
                .shadow(color: designSystem.shadowColor, radius: designSystem.shadowRadius)
            
            if let systemImageName = designSystem.cardPlaceholderSystemImage {
                Image(systemName: systemImageName)
                    .foregroundColor(designSystem.borderColor)
                    .font(.system(size: designSystem.cardSize * 0.4))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the horizontal offset for a card at the given index
    private func xOffset(for index: Int) -> CGFloat {
        return designSystem.cardSpacing * CGFloat(index)
    }
    
    /// Calculate the rotation angle for a card at the given index
    private func rotationAngle(for index: Int) -> Double {
        // Center card is straight, others fan out
        let middleIndex = Double(pieces.count - 1) / 2.0
        let indexDiff = Double(index) - middleIndex
        return indexDiff * Double(designSystem.cardRotation)
    }
    
    /// Calculate the total width of the stack
    private var stackWidth: CGFloat {
        if pieces.isEmpty {
            return designSystem.cardSize // Just the circle width
        } else {
            // Width of first card + offset of last card + width of last card
            return designSystem.cardSize + xOffset(for: pieces.count - 1)
        }
    }
    
    // MARK: - Public Methods
    
    /// Replaces the top card in the stack with a new image, using animation
    /// - Parameter newImage: The new image to place on top of the stack
    /// - Returns: A modified ImageCardStack with the animation in progress
    public func replaceTopCard(with newImage: Item) -> Self {
        let copy = self
        
        // Only proceed if there are images in the stack
        if !copy.pieces.isEmpty {
            copy.replacementImage = newImage
            copy.isAnimatingReplacement = true
            
            // Set initial animation states
            copy.replacementOffset = -50
            copy.replacementOpacity = 0
            copy.topCardOffset = 0
            copy.topCardOpacity = 1
            
            // Start the animation sequence
            withAnimation(.easeInOut(duration: copy.replacementAnimationDuration)) {
                // Animate the current top card out
                copy.topCardOffset = 50
                copy.topCardOpacity = 0
                
                // Animate the new card in
                copy.replacementOffset = 0
                copy.replacementOpacity = 1
            }
            
            // After animation completes, update the actual images array
            DispatchQueue.main.asyncAfter(deadline: .now() + copy.replacementAnimationDuration + 0.1) {
                if var updatedPieces = copy.pieces as? [Item], !updatedPieces.isEmpty {
                    // Replace the top card
                    updatedPieces[updatedPieces.count - 1] = newImage
                    copy.pieces = updatedPieces
                    
                    // Reset animation states
                    copy.isAnimatingReplacement = false
                    copy.replacementImage = nil
                    copy.topCardOffset = 0
                    copy.topCardOpacity = 1
                }
            }
        }
        
        return copy
    }
}

// MARK: - Preview
#if DEBUG
struct ImageCardStack_Previews: PreviewProvider {
    struct AnimatedCardStackDemo: View {
        @StateObject private var viewModel = EvidenceViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo", isChecked: false),
                CheckboxItem(text: "Scan barcode", isChecked: false),
                CheckboxItem(text: "Capture Sales Receipt", isChecked: false)
            ],
            pieces: [
                .system("photo"),
                .system("camera"),
                .system("doc.text.image")
            ],
            designSystem: DesignSystemSetup(
                textColor: .white,
                accentColor: .white,
                backgroundColor: .clear,
                borderColor: .white.opacity(0.2),
                shadowColor: .black.opacity(0.3),
                placeholderColor: .white.opacity(0.2),
                cardSpacing: 12,
                cardSize: 60,
                cardRotation: 4
            )
        )
        
        @State private var replacementImages: [EvidencePiece] = [
            .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
            .system("star.fill"),
            .system("heart.fill"),
            .system("bell.fill"),
            .system("bookmark.fill")
        ]
        
        @State private var currentIndex = 0
        
        var body: some View {
            VStack {
                Text("Animated Card Replacement")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                ImageCardStack(pieces: viewModel.pieces, designSystem: viewModel.designSystem)
                    .padding()
                
                Button("Replace Top Card") {
                    // Get the next replacement image
                    let nextImage = replacementImages[currentIndex]
                    
                    // Update the stack with animation
                    if !viewModel.pieces.isEmpty {
                        viewModel.replaceTopPiece(with: nextImage)
                    }
                    
                    // Move to the next replacement image
                    currentIndex = (currentIndex + 1) % replacementImages.count
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
    
    static var previews: some View {
        VStack(spacing: 40) {
            // Animated card replacement demo
            AnimatedCardStackDemo()
            
            // Full stack of 5 custom images
            VStack {
                Text("5 Custom Images")
                    .font(.headline)
                
                ImageCardStack(
                    pieces: [
                        EvidencePiece.custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                        EvidencePiece.custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                        EvidencePiece.custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                        EvidencePiece.custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                        EvidencePiece.custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
                    ],
                    designSystem: DesignSystemSetup(
                        cardSpacing: 15,
                        cardSize: 70,
                        cardRotation: 5
                    )
                )
            }
            
            // Stack of 3 system images with metadata
            VStack {
                Text("3 System Images")
                    .font(.headline)
                
                ImageCardStack(
                    pieces: [
                        EvidencePiece(index: 0, title: "photo", type: .system("photo"), metadata: ["type": "camera"]),
                        EvidencePiece(index: 1, title: "camera", type: .system("camera"), metadata: ["type": "capture"]),
                        EvidencePiece(index: 2, title: "document", type: .system("doc.text.image"), metadata: ["type": "document"])
                    ],
                    designSystem: DesignSystemSetup(
                        borderColor: .blue,
                        shadowColor: .blue.opacity(0.3),
                        cardSpacing: 12,
                        cardSize: 60,
                        cardRotation: 4
                    )
                )
            }
            
            // Stack of 1 image with timestamp
            VStack {
                Text("Single Image")
                    .font(.headline)
                
                ImageCardStack(
                    pieces: [
                        EvidencePiece(index: 0, title: "",
                            type: .system("photo.fill"),
                            metadata: ["captured_at": "12:30 PM"],
                            timestamp: Date()
                        )
                    ],
                    designSystem: DesignSystemSetup(
                        borderColor: .green,
                        cardSize: 50,
                        borderWidth: 2,
                        cornerRadius: 25 // Circle
                    )
                )
            }
            
            // Empty stack with placeholder
            VStack {
                Text("Empty Stack")
                    .font(.headline)
                
                ImageCardStack<EvidencePiece>(
                
                    pieces: [],
                    designSystem: DesignSystemSetup(
                        placeholderColor: .gray.opacity(0.2),
                        cardSize: 60
                    )
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
#endif
