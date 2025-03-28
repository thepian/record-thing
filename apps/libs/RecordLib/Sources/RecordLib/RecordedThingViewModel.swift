import SwiftUI
import os

/// ViewModel for managing the state and business logic of RecordedStackAndRequirementsView
/*
    This view model is responsible for managing the state and business logic of the RecordedStackAndRequirementsView.
    - Actions that have been done (for current thing)
    - Actions that have not yet been done (for current thing)
    - Evidence already recorded (for current thing)
    - Most recent evidence (with open questions)
    
*/
@MainActor
public class RecordedThingViewModel: ObservableObject {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger: Logger = Logger(subsystem: "com.record-thing", category: "ui.checkbox-image-card")
    
    // Published state
    @Published public var checkboxItems: [CheckboxItem]
    @Published public var cardImages: [ImageCardStack.CardImage]
    @Published public var isAnimating: Bool = false
    
    // Evidence properties
    @Published public var evidenceOptions: [String] = []
    @Published public var evidenceDecision: String?
    @Published public var evidenceTitle: String = ""
    
    // Evidence review properties
    @Published public var evidenceReviewImage: RecordImage?
    @Published public var evidenceReviewClip: URL?
    
    // Configuration
    public var direction: RecordedStackAndRequirementsView.LayoutDirection
    public let spacing: CGFloat
    public let alignment: HorizontalAlignment
    
    // Design system
    @Published public var designSystem: DesignSystemSetup
    
    // Checkbox configuration
    public let maxCheckboxItems: Int
    public let checkboxOrientation: CarouselOrientation
    
    // Image stack configuration
    public var showCardBorder: Bool
    public var cardPlaceholderSystemImage: String?
    
    // Callbacks
    private let onCardStackTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new RecordedThingViewModel
    /// - Parameters:
    ///   - checkboxItems: Array of checkbox items to display
    ///   - cardImages: Array of images to display in the card stack
    ///   - direction: Direction of the layout (horizontal or vertical)
    ///   - spacing: Spacing between the checkbox carousel and image stack
    ///   - alignment: Horizontal alignment of the components
    ///   - maxCheckboxItems: Maximum number of checkbox items visible at once
    ///   - designSystem: Design system configuration for styling
    ///   - evidenceOptions: Array of evidence options to cycle through
    ///   - evidenceDecision: The selected evidence option
    ///   - evidenceTitle: Title to display instead of cycling through options
    ///   - evidenceReviewImage: Image to display in the evidence review overlay
    ///   - evidenceReviewClip: URL of the video clip to display in the evidence review overlay
    ///   - onCardStackTapped: Callback when the image card stack is tapped
    public init(
        checkboxItems: [CheckboxItem],
        cardImages: [ImageCardStack.CardImage],
        direction: RecordedStackAndRequirementsView.LayoutDirection = .horizontal,
        spacing: CGFloat = 2,
        alignment: HorizontalAlignment = .leading,
        maxCheckboxItems: Int = 1,
        checkboxOrientation: CarouselOrientation = .horizontal,
        designSystem: DesignSystemSetup = .light,
        evidenceOptions: [String] = [],
        evidenceDecision: String? = nil,
        evidenceTitle: String = "",
        evidenceReviewImage: RecordImage? = nil,
        evidenceReviewClip: URL? = nil,
        onCardStackTapped: (() -> Void)? = nil
    ) {
        self.checkboxItems = checkboxItems
        self.cardImages = cardImages
        self.direction = direction
        self.spacing = spacing
        self.alignment = alignment
        self.maxCheckboxItems = maxCheckboxItems
        self.designSystem = designSystem
        
        // Evidence properties
        self.evidenceOptions = evidenceOptions
        self.evidenceDecision = evidenceDecision
        self.evidenceTitle = evidenceTitle
        self.evidenceReviewImage = evidenceReviewImage
        self.evidenceReviewClip = evidenceReviewClip
        
        // Checkbox configuration
        self.checkboxOrientation = checkboxOrientation
        
        // Image stack configuration
        self.showCardBorder = true
        self.cardPlaceholderSystemImage = nil
        
        // Callbacks
        self.onCardStackTapped = onCardStackTapped
        
        logger.debug("RecordedThingViewModel initialized with \(checkboxItems.count) checkbox items, \(cardImages.count) card images, \(evidenceOptions.count) evidence options")
    }
    
    // MARK: - Public Methods
    
    /// Updates the checkbox items
    /// - Parameter newItems: The new checkbox items
    public func updateCheckboxItems(_ newItems: [CheckboxItem]) {
        checkboxItems = newItems
        logger.debug("Updated checkbox items to \(newItems.count) items")
    }
    
    /// Updates the card images
    /// - Parameter newImages: The new card images
    public func updateCardImages(_ newImages: [ImageCardStack.CardImage]) {
        cardImages = newImages
        logger.debug("Updated card images to \(newImages.count) images")
    }
    
    /// Replaces the top card in the image stack with a new image
    /// - Parameter newImage: The new image to place on top of the stack
    public func replaceTopCard(with newImage: ImageCardStack.CardImage) {
        guard !cardImages.isEmpty else {
            logger.debug("Cannot replace top card: no cards in stack")
            return
        }
        
        isAnimating = true
        logger.debug("Starting card replacement animation")
        
        // Update the card images after the animation completes
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(0.6 * 1_000_000_000))
            if !cardImages.isEmpty {
                var updatedImages = cardImages
                updatedImages[updatedImages.count - 1] = newImage
                cardImages = updatedImages
                isAnimating = false
                logger.debug("Completed card replacement animation")
            }
        }
    }
    
    /// Handles the card stack being tapped
    public func handleCardStackTapped() {
        logger.debug("Card stack tapped")
        onCardStackTapped?()
    }
    
    /// Resets all checkbox items to unchecked state
    public func resetCheckboxItems() {
        checkboxItems = checkboxItems.map { item in
            var updatedItem = item
            updatedItem.isChecked = false
            return updatedItem
        }
        logger.debug("Reset all checkbox items to unchecked state")
    }
    
    // MARK: - Checkbox Items Management
    
    /// Updates checkbox items based on a category
    /// - Parameter category: The category to update items for
    public func updateCheckboxItems(for category: AssetCategory) {
        switch category {
        case .watches:
            checkboxItems = [
                CheckboxItem(text: "Take watch photo"),
                CheckboxItem(text: "Scan serial number"),
                CheckboxItem(text: "Capture warranty card")
            ]
        case .bags:
            checkboxItems = [
                CheckboxItem(text: "Take bag photo"),
                CheckboxItem(text: "Scan authenticity code"),
                CheckboxItem(text: "Capture receipt")
            ]
        default:
            checkboxItems = [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ]
        }
        logger.debug("Updated checkbox items for category: \(category.displayName)")
    }
    
    public func toggleCheckboxItem(_ item: CheckboxItem) {
        if let index = checkboxItems.firstIndex(where: { $0.id == item.id }) {
            checkboxItems[index].isChecked.toggle()
            logger.debug("Toggled checkbox item: \(self.checkboxItems[index].text), isChecked: \(self.checkboxItems[index].isChecked)")
        }
    }
} 
