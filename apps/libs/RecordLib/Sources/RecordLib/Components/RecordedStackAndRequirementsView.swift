import SwiftUI
import os

/// A component that combines CheckboxCarouselView and ImageCardStack side-by-side.
///
/// This component is useful for displaying a list of checkable items alongside a stack of images,
/// which can be used for tasks like selecting options while viewing related images.
///
/// Features:
/// - Displays a CheckboxCarouselView on one side and an ImageCardStack on the other
/// - Customizable layout direction (horizontal or vertical)
/// - Configurable spacing between components
/// - Fully customizable checkbox carousel and image card stack
/// - Optional title for each section
/// - Callbacks for checkbox toggling and image stack tapping
///
/// Example usage:
/// ```swift
/// CheckboxImageCardView(
///     checkboxItems: [
///         CheckboxItem(text: "Take a photo"),
///         CheckboxItem(text: "Scan barcode", isChecked: true),
///         CheckboxItem(text: "Add details")
///     ],
///     cardImages: [
///         .system("photo"),
///         .system("camera"),
///         .system("doc.text.image")
///     ]
/// )
/// ```
public struct RecordedStackAndRequirementsView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.checkbox-image-card")
    
    // Content
    @State private var checkboxItems: [CheckboxItem]
    @State private var cardImages: [ImageCardStack.CardImage]
    
    // Layout
    private let direction: LayoutDirection
    private let spacing: CGFloat
    private let alignment: HorizontalAlignment
    
    // Checkbox configuration
    private let maxVisibleItems: Int
    private let checkboxTextColor: Color
    private let checkboxColor: Color
    private let checkboxAnimationDuration: Double
    private let checkboxItemHeight: CGFloat
    private let checkboxSpacing: CGFloat
    private let checkboxOrientation: CarouselOrientation
    private let checkboxStyle: CheckboxStyle
    private let showCheckboxBorder: Bool
    private let checkboxTextAlignment: CheckboxTextAlignment
    
    // Image stack configuration
    private let cardSize: CGFloat
    private let cardSpacing: CGFloat
    private let cardRotation: CGFloat
    private let cardCornerRadius: CGFloat
    private let showCardBorder: Bool
    private let cardBorderColor: Color
    private let cardBorderWidth: CGFloat
    private let showCardShadow: Bool
    private let cardShadowColor: Color
    private let cardShadowRadius: CGFloat
    private let cardPlaceholderColor: Color
    private let cardPlaceholderSystemImage: String?
    
    // Callbacks
    private let onItemToggled: ((CheckboxItem) -> Void)?
    private let onCardStackTapped: (() -> Void)?
    
    // MARK: - Types
    
    /// Direction of the layout
    public enum LayoutDirection {
        case horizontal  // Checkbox on left, images on right
        case vertical    // Checkbox on top, images on bottom
    }
    
    // MARK: - Initialization
    
    /// Creates a new CheckboxImageCardView
    /// - Parameters:
    ///   - checkboxItems: Array of checkbox items to display
    ///   - cardImages: Array of images to display in the card stack
    ///   - direction: Direction of the layout (horizontal or vertical)
    ///   - spacing: Spacing between the checkbox carousel and image stack
    ///   - alignment: Horizontal alignment of the components
    ///   - maxVisibleItems: Maximum number of checkbox items visible at once
    ///   - checkboxTextColor: Color of the checkbox text
    ///   - checkboxColor: Color of the checkbox
    ///   - checkboxAnimationDuration: Duration of checkbox animations
    ///   - checkboxItemHeight: Height of each checkbox item
    ///   - checkboxSpacing: Spacing between checkbox items
    ///   - checkboxOrientation: Direction of the checkbox carousel
    ///   - checkboxStyle: Style of the checkbox
    ///   - showCheckboxBorder: Whether to show the border line for checkbox carousel
    ///   - checkboxTextAlignment: Alignment of text and checkmark
    ///   - cardSize: Size of each card in the stack
    ///   - cardSpacing: Horizontal spacing between cards
    ///   - cardRotation: Rotation angle in degrees between cards
    ///   - cardCornerRadius: Corner radius of each card
    ///   - showCardBorder: Whether to show a border around each card
    ///   - cardBorderColor: Color of the card border
    ///   - cardBorderWidth: Width of the card border
    ///   - showCardShadow: Whether to show a shadow under each card
    ///   - cardShadowColor: Color of the card shadow
    ///   - cardShadowRadius: Radius of the card shadow
    ///   - cardPlaceholderColor: Color of the placeholder circle when no images are present
    ///   - cardPlaceholderSystemImage: Optional system image to display in the placeholder
    ///   - onItemToggled: Callback when a checkbox item is toggled
    ///   - onCardStackTapped: Callback when the image card stack is tapped
    public init(
        checkboxItems: [CheckboxItem],
        cardImages: [ImageCardStack.CardImage],
        direction: LayoutDirection = .horizontal,
        spacing: CGFloat = 2,
        alignment: HorizontalAlignment = .leading,
        
        // Checkbox configuration
        maxVisibleItems: Int = 1,
        checkboxTextColor: Color = .primary,
        checkboxColor: Color = .blue,
        checkboxAnimationDuration: Double = 0.5,
        checkboxItemHeight: CGFloat = 44,
        checkboxSpacing: CGFloat = 8,
        checkboxOrientation: CarouselOrientation = .horizontal,
        checkboxStyle: CheckboxStyle = .simple,
        showCheckboxBorder: Bool = false,
        checkboxTextAlignment: CheckboxTextAlignment = .right,
        
        // Image stack configuration
        cardSize: CGFloat = 60,
        cardSpacing: CGFloat = 10,
        cardRotation: CGFloat = 3,
        cardCornerRadius: CGFloat = 8,
        showCardBorder: Bool = true,
        cardBorderColor: Color = .white.opacity(0.2),
        cardBorderWidth: CGFloat = 1,
        showCardShadow: Bool = true,
        cardShadowColor: Color = .white.opacity(0.3),
        cardShadowRadius: CGFloat = 4,
        cardPlaceholderColor: Color = .gray.opacity(0.2),
        cardPlaceholderSystemImage: String? = nil,
        
        // Callbacks
        onItemToggled: ((CheckboxItem) -> Void)? = nil,
        onCardStackTapped: (() -> Void)? = nil
    ) {
        self._checkboxItems = State(initialValue: checkboxItems)
        self._cardImages = State(initialValue: cardImages)
        self.direction = direction
        self.spacing = spacing
        self.alignment = alignment
        
        // Checkbox configuration
        self.maxVisibleItems = maxVisibleItems
        self.checkboxTextColor = checkboxTextColor
        self.checkboxColor = checkboxColor
        self.checkboxAnimationDuration = checkboxAnimationDuration
        self.checkboxItemHeight = checkboxItemHeight
        self.checkboxSpacing = checkboxSpacing
        self.checkboxOrientation = checkboxOrientation
        self.checkboxStyle = checkboxStyle
        self.showCheckboxBorder = showCheckboxBorder
        self.checkboxTextAlignment = checkboxTextAlignment
        
        // Image stack configuration
        self.cardSize = cardSize
        self.cardSpacing = cardSpacing
        self.cardRotation = cardRotation
        self.cardCornerRadius = cardCornerRadius
        self.showCardBorder = showCardBorder
        self.cardBorderColor = cardBorderColor
        self.cardBorderWidth = cardBorderWidth
        self.showCardShadow = showCardShadow
        self.cardShadowColor = cardShadowColor
        self.cardShadowRadius = cardShadowRadius
        self.cardPlaceholderColor = cardPlaceholderColor
        self.cardPlaceholderSystemImage = cardPlaceholderSystemImage
        
        // Callbacks
        self.onItemToggled = onItemToggled
        self.onCardStackTapped = onCardStackTapped
        
        logger.debug("CheckboxImageCardView initialized with \(checkboxItems.count) checkbox items and \(cardImages.count) card images")
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if direction == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Horizontal layout with checkbox on left, images on right
    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: spacing) {
            // Checkbox section
            VStack(alignment: alignment) {
                checkboxCarousel
            }
            
            // Image stack section
            VStack(alignment: alignment) {
                imageCardStack
            }
        }
    }
    
    /// Vertical layout with checkbox on top, images on bottom
    private var verticalLayout: some View {
        VStack(alignment: alignment, spacing: spacing) {
            // Checkbox section
            VStack(alignment: alignment) {
                checkboxCarousel
            }
            
            // Image stack section
            VStack(alignment: alignment) {
                imageCardStack
            }
        }
    }
    
    /// Checkbox carousel component
    private var checkboxCarousel: some View {
        CheckboxCarouselView(
            items: checkboxItems,
            maxVisibleItems: maxVisibleItems,
            textColor: checkboxTextColor,
            checkboxColor: checkboxColor,
            animationDuration: checkboxAnimationDuration,
            itemHeight: checkboxItemHeight,
            spacing: checkboxSpacing,
            orientation: checkboxOrientation,
            checkboxStyle: checkboxStyle,
            showBorder: showCheckboxBorder,
            textAlignment: checkboxTextAlignment,
            onItemToggled: { item in
                logger.debug("Checkbox item toggled: \(item.text), isChecked: \(item.isChecked)")
                onItemToggled?(item)
            }
        )
    }
    
    /// Image card stack component
    private var imageCardStack: some View {
        ImageCardStack(
            images: cardImages,
            size: cardSize,
            spacing: cardSpacing,
            rotation: cardRotation,
            cornerRadius: cardCornerRadius,
            showBorder: showCardBorder,
            borderColor: cardBorderColor,
            borderWidth: cardBorderWidth,
            showShadow: showCardShadow,
            shadowColor: cardShadowColor,
            shadowRadius: cardShadowRadius,
            placeholderColor: cardPlaceholderColor,
            placeholderSystemImage: cardPlaceholderSystemImage,
            onTap: {
                logger.debug("Image card stack tapped")
                onCardStackTapped?()
            }
        )
    }
    
    // MARK: - Public Methods
    
    /// Updates the checkbox items
    /// - Parameter newItems: The new checkbox items
    /// - Returns: A modified CheckboxImageCardView with updated checkbox items
    public func updateCheckboxItems(_ newItems: [CheckboxItem]) -> Self {
        var copy = self
        copy._checkboxItems = State(initialValue: newItems)
        return copy
    }
    
    /// Updates the card images
    /// - Parameter newImages: The new card images
    /// - Returns: A modified CheckboxImageCardView with updated card images
    public func updateCardImages(_ newImages: [ImageCardStack.CardImage]) -> Self {
        var copy = self
        copy._cardImages = State(initialValue: newImages)
        return copy
    }
    
    /// Replaces the top card in the image stack with a new image
    /// - Parameter newImage: The new image to place on top of the stack
    /// - Returns: A modified CheckboxImageCardView with the animation in progress
    public func replaceTopCard(with newImage: ImageCardStack.CardImage) -> Self {
        var copy = self
        
        // Create a new ImageCardStack with the replacement animation
        let updatedStack = ImageCardStack(
            images: cardImages,
            size: cardSize,
            spacing: cardSpacing,
            rotation: cardRotation,
            cornerRadius: cardCornerRadius,
            showBorder: showCardBorder,
            borderColor: cardBorderColor,
            borderWidth: cardBorderWidth,
            showShadow: showCardShadow,
            shadowColor: cardShadowColor,
            shadowRadius: cardShadowRadius,
            placeholderColor: cardPlaceholderColor,
            placeholderSystemImage: cardPlaceholderSystemImage,
            onTap: onCardStackTapped
        ).replaceTopCard(with: newImage)
        
        // Update the card images after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if !copy.cardImages.isEmpty {
                var updatedImages = copy.cardImages
                updatedImages[updatedImages.count - 1] = newImage
                copy._cardImages = State(initialValue: updatedImages)
            }
        }
        
        return copy
    }
}

// MARK: - Preview

struct CheckboxImageCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Horizontal layout with titles
            RecordedStackAndRequirementsView(
                checkboxItems: [
                    CheckboxItem(text: "Take a photo of the product"),
                    CheckboxItem(text: "Scan the barcode", isChecked: true),
                    CheckboxItem(text: "Capture the receipt"),
                    CheckboxItem(text: "Add product details")
                ],
                cardImages: [
                    .system("photo"),
                    .system("camera"),
                    .system("doc.text.image")
                ],
                direction: .horizontal,
                onItemToggled: { item in
                    print("Item toggled: \(item.text), isChecked: \(item.isChecked)")
                },
                onCardStackTapped: {
                    print("Card stack tapped")
                }
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Horizontal with Titles")
            
            // Vertical layout with custom styling
            RecordedStackAndRequirementsView(
                checkboxItems: [
                    CheckboxItem(text: "First item"),
                    CheckboxItem(text: "Second item", isChecked: true)
                ],
                cardImages: [
                    .system("star.fill"),
                    .system("heart.fill")
                ],
                direction: .vertical,
                checkboxTextColor: .blue,
                checkboxColor: .orange,
                checkboxStyle: .simple,
                cardSize: 50,
                cardRotation: 5,
                cardBorderColor: .blue
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Vertical with Custom Styling")
            
            // Dark mode preview
            RecordedStackAndRequirementsView(
                checkboxItems: [
                    CheckboxItem(text: "Dark mode item 1"),
                    CheckboxItem(text: "Dark mode item 2")
                ],
                cardImages: [
                    .system("moon.fill"),
                    .system("star.fill")
                ],
                checkboxTextColor: .white,
                checkboxColor: .white,
                cardBorderColor: .white
            )
            .previewLayout(.sizeThatFits)
            .background(Color.black)
            .previewDisplayName("Dark Mode")
        }
    }
}
