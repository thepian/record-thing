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
/// // With custom images
/// ImageCardStack(
///     images: [
///         .custom(Image("card1")),
///         .custom(Image("card2")),
///         .custom(Image("card3"))
///     ],
///     size: 60
/// )
///
/// // With system images
/// ImageCardStack(
///     images: [
///         .system("photo"),
///         .system("camera"),
///         .system("doc")
///     ],
///     size: 50,
///     spacing: 8,
///     rotation: 5
/// )
///
/// // Empty stack
/// ImageCardStack(
///     images: [],
///     size: 40,
///     placeholderColor: .gray.opacity(0.3)
/// )
/// ```
public struct ImageCardStack: View {
    // MARK: - Types
    
    /// Represents an image in the card stack
    public enum CardImage: Equatable {
        case system(String)      // System SF Symbol name
        case custom(Image)       // Custom image
        
        var image: Image {
            switch self {
            case .system(let name):
                return Image(systemName: name)
            case .custom(let image):
                return image
            }
        }
        
        // Implement Equatable for CardImage
        public static func == (lhs: CardImage, rhs: CardImage) -> Bool {
            switch (lhs, rhs) {
            case (.system(let lhsName), .system(let rhsName)):
                return lhsName == rhsName
            case (.custom, .custom):
                // Can't compare Images directly, so we'll consider all custom images different
                // This is a limitation, but works for most use cases
                return false
            default:
                return false
            }
        }
    }
    
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.image-card-stack")
    
    // Content
    @State private var images: [CardImage]
    @State private var isAnimatingReplacement: Bool = false
    @State private var replacementImage: CardImage?
    @State private var replacementOffset: CGFloat = 50
    @State private var replacementOpacity: Double = 0
    @State private var topCardOffset: CGFloat = 0
    @State private var topCardOpacity: Double = 1
    
    // Configuration
    private let size: CGFloat
    private let spacing: CGFloat
    private let rotation: CGFloat
    private let cornerRadius: CGFloat
    private let showBorder: Bool
    private let borderColor: Color
    private let borderWidth: CGFloat
    private let showShadow: Bool
    private let shadowColor: Color
    private let shadowRadius: CGFloat
    private let placeholderColor: Color
    private let placeholderSystemImage: String?
    private let onTap: (() -> Void)?
    private let replacementAnimationDuration: Double
    
    // MARK: - Initialization
    
    /// Creates a new ImageCardStack
    /// - Parameters:
    ///   - images: Array of images to display in the stack (max 5)
    ///   - size: Size of each card (width and height)
    ///   - spacing: Horizontal spacing between cards
    ///   - rotation: Rotation angle in degrees between cards
    ///   - cornerRadius: Corner radius of each card
    ///   - showBorder: Whether to show a border around each card
    ///   - borderColor: Color of the border
    ///   - borderWidth: Width of the border
    ///   - showShadow: Whether to show a shadow under each card
    ///   - shadowColor: Color of the shadow
    ///   - shadowRadius: Radius of the shadow
    ///   - placeholderColor: Color of the placeholder circle when no images are present
    ///   - placeholderSystemImage: Optional system image to display in the placeholder
    ///   - replacementAnimationDuration: Duration of the card replacement animation
    ///   - onTap: Action to perform when the stack is tapped
    public init(
        images: [CardImage],
        size: CGFloat = 60,
        spacing: CGFloat = 10,
        rotation: CGFloat = 3,
        cornerRadius: CGFloat = 8,
        showBorder: Bool = true,
        borderColor: Color = .white,
        borderWidth: CGFloat = 1,
        showShadow: Bool = true,
        shadowColor: Color = .black.opacity(0.3),
        shadowRadius: CGFloat = 2,
        placeholderColor: Color = .gray.opacity(0.2),
        placeholderSystemImage: String? = nil,
        replacementAnimationDuration: Double = 0.5,
        onTap: (() -> Void)? = nil
    ) {
        // Limit to 5 images maximum
        self._images = State(initialValue: Array(images.prefix(5)))
        self.size = size
        self.spacing = spacing
        self.rotation = rotation
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.showShadow = showShadow
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.placeholderColor = placeholderColor
        self.placeholderSystemImage = placeholderSystemImage
        self.replacementAnimationDuration = replacementAnimationDuration
        self.onTap = onTap
        
        logger.debug("ImageCardStack initialized with \(images.count) images")
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            if images.isEmpty {
                // Placeholder when no images are present
                emptyPlaceholder
            } else {
                // Fanned stack of images
                cardStack
                
                // Replacement card animation
                if isAnimatingReplacement, let replacement = replacementImage {
                    cardView(for: replacement)
                        .offset(x: xOffset(for: images.count - 1), y: replacementOffset)
                        .rotationEffect(.degrees(rotationAngle(for: images.count - 1)))
                        .opacity(replacementOpacity)
                        .zIndex(Double(images.count + 1))
                }
            }
        }
        .frame(width: stackWidth, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            logger.debug("ImageCardStack tapped")
            onTap?()
        }
    }
    
    // MARK: - UI Components
    
    /// The fanned stack of cards
    private var cardStack: some View {
        ZStack {
            // Display cards from back to front
            ForEach(0..<images.count, id: \.self) { index in
                if index == images.count - 1 && isAnimatingReplacement {
                    // Top card that's being replaced
                    cardView(for: index)
                        .offset(x: xOffset(for: index), y: topCardOffset)
                        .rotationEffect(.degrees(rotationAngle(for: index)))
                        .opacity(topCardOpacity)
                        .zIndex(Double(index))
                } else {
                    // Regular cards
                    cardView(for: index)
                        .offset(x: xOffset(for: index))
                        .rotationEffect(.degrees(rotationAngle(for: index)))
                        .zIndex(Double(index))
                }
            }
        }
    }
    
    /// A single card in the stack
    private func cardView(for index: Int) -> some View {
        images[index].image
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
            .shadow(color: showShadow ? shadowColor : .clear, radius: shadowRadius)
    }
    
    /// A single card view for a replacement card
    private func cardView(for image: CardImage) -> some View {
        image.image
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
            .shadow(color: showShadow ? shadowColor : .clear, radius: shadowRadius)
    }
    
    /// Placeholder shown when no images are present
    private var emptyPlaceholder: some View {
        ZStack {
            Circle()
                .fill(placeholderColor)
                .frame(width: size, height: size)
                .overlay(
                    Group {
                        if showBorder {
                            Circle()
                                .stroke(borderColor, lineWidth: borderWidth)
                        }
                    }
                )
                .shadow(color: showShadow ? shadowColor : .clear, radius: shadowRadius)
            
            if let systemImageName = placeholderSystemImage {
                Image(systemName: systemImageName)
                    .foregroundColor(borderColor)
                    .font(.system(size: size * 0.4))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the horizontal offset for a card at the given index
    private func xOffset(for index: Int) -> CGFloat {
        return spacing * CGFloat(index)
    }
    
    /// Calculate the rotation angle for a card at the given index
    private func rotationAngle(for index: Int) -> Double {
        // Center card is straight, others fan out
        let middleIndex = Double(images.count - 1) / 2.0
        let indexDiff = Double(index) - middleIndex
        return indexDiff * Double(rotation)
    }
    
    /// Calculate the total width of the stack
    private var stackWidth: CGFloat {
        if images.isEmpty {
            return size // Just the circle width
        } else {
            // Width of first card + offset of last card + width of last card
            return size + xOffset(for: images.count - 1)
        }
    }
    
    // MARK: - Public Methods
    
    /// Replaces the top card in the stack with a new image, using animation
    /// - Parameter newImage: The new image to place on top of the stack
    /// - Returns: A modified ImageCardStack with the animation in progress
    public func replaceTopCard(with newImage: CardImage) -> Self {
        var copy = self
        
        // Only proceed if there are images in the stack
        if !copy.images.isEmpty {
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
                if var updatedImages = copy.images as? [CardImage], !updatedImages.isEmpty {
                    // Replace the top card
                    updatedImages[updatedImages.count - 1] = newImage
                    copy.images = updatedImages
                    
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

struct ImageCardStack_Previews: PreviewProvider {
    struct AnimatedCardStackDemo: View {
        @State private var stack = ImageCardStack(
            images: [
                .system("photo"),
                .system("camera"),
                .system("doc.text.image")
            ],
            size: 60,
            spacing: 12,
            rotation: 4,
            borderColor: .white,
            shadowColor: .black.opacity(0.3)
        )
        
        @State private var replacementImages: [ImageCardStack.CardImage] = [
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
                
                stack
                    .padding()
                
                Button("Replace Top Card") {
                    // Get the next replacement image
                    let nextImage = replacementImages[currentIndex]
                    
                    // Update the stack with animation
                    stack = stack.replaceTopCard(with: nextImage)
                    
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
                    images: [
                        .custom(Image("thepia_a_high-end_electric_mountain_bike_1")),
                        .custom(Image("thepia_a_high-end_electric_mountain_bike_1")),
                        .custom(Image("thepia_a_high-end_electric_mountain_bike_1")),
                        .custom(Image("thepia_a_high-end_electric_mountain_bike_1")),
                        .custom(Image("thepia_a_high-end_electric_mountain_bike_1"))
                    ],
                    size: 70,
                    spacing: 15,
                    rotation: 5,
                    onTap: {
                        print("Full stack tapped")
                    }
                )
            }
            
            // Stack of 3 system images
            VStack {
                Text("3 System Images")
                    .font(.headline)
                
                ImageCardStack(
                    images: [
                        .system("photo"),
                        .system("camera"),
                        .system("doc.text.image")
                    ],
                    size: 60,
                    spacing: 12,
                    rotation: 4,
                    borderColor: .blue,
                    shadowColor: .blue.opacity(0.3),
                    onTap: {
                        print("System images stack tapped")
                    }
                )
            }
            
            // Stack of 1 image
            VStack {
                Text("Single Image")
                    .font(.headline)
                
                ImageCardStack(
                    images: [
                        .system("photo.fill")
                    ],
                    size: 50,
                    cornerRadius: 25, // Circle
                    borderColor: .green,
                    borderWidth: 2,
                    onTap: {
                        print("Single image stack tapped")
                    }
                )
            }
            
            // Empty stack with placeholder
            VStack {
                Text("Empty Stack")
                    .font(.headline)
                
                ImageCardStack(
                    images: [],
                    size: 60,
                    placeholderColor: .gray.opacity(0.2),
                    placeholderSystemImage: "photo.stack",
                    onTap: {
                        print("Empty stack tapped")
                    }
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
