import SwiftUI
import os
import CoreGraphics
import CoreImage
import AVFoundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Used by Carousel for cards
public protocol CardViewData: Equatable, Identifiable {
    var id: UUID { get }
    var _index: Int { get }
    var title: String { get }
    var image: Image? { get }
    var color: Color { get }
    var imageWidth: CGFloat? { get }
    var imageHeight: CGFloat? { get }
}

/// The type of evidence piece
public enum EvidenceType: Equatable {
    case system(String)      // System SF Symbol name
    case custom(Image)       // Custom image
    case video(URL)         // Video URL
}

/// Represents a piece of evidence with associated metadata
public struct EvidencePiece: CardViewData {
    public let id: UUID
    public let _index: Int
    public let title: String
    public var color: Color
    public let type: EvidenceType
    public let timestamp: Date
    public let metadata: [String: String]
    
    // Add image dimensions
    public var imageWidth: CGFloat?
    public var imageHeight: CGFloat?
    private var hasLoadedDimensions: Bool = false
    
    // Logger for debugging
    private static let logger = Logger(subsystem: "com.record-thing", category: "EvidencePiece")
    
    /// Creates a new piece of evidence
    /// - Parameters:
    ///   - type: The type of evidence (system image, custom image, or video)
    ///   - metadata: Optional metadata associated with the evidence
    ///   - timestamp: When the evidence was captured (defaults to now)
    public init(
        index: Int = -1,
        title: String,
        type: EvidenceType,
        metadata: [String: String] = [:],
        timestamp: Date = Date(),
        color: Color = .red,
        imageWidth: CGFloat? = nil,
        imageHeight: CGFloat? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.metadata = metadata
        self.timestamp = timestamp
        self._index = index
        self.color = color
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
    
    /// Creates a copy of an existing evidence piece with optional updates
    /// - Parameters:
    ///   - original: The piece to copy
    ///   - type: Optional new type (uses original if nil)
    ///   - metadata: Optional new metadata (merges with original if provided)
    ///   - timestamp: Optional new timestamp (uses original if nil)
    public init(
        _ original: EvidencePiece,
        index: Int? = nil,
        title: String? = nil,
        type: EvidenceType? = nil,
        metadata: [String: String]? = nil,
        timestamp: Date? = nil,
        color: Color = .red,
        imageWidth: CGFloat? = nil,
        imageHeight: CGFloat? = nil
    ) {
        self.id = original.id  // Preserve the original ID
        self._index = index ?? original._index
        self.title = title ?? original.title
        self.type = type ?? original.type
        self.metadata = metadata ?? original.metadata
        self.timestamp = timestamp ?? original.timestamp
        self.color = color
        self.imageWidth = imageWidth ?? original.imageWidth
        self.imageHeight = imageHeight ?? original.imageHeight
    }
    
    public static func == (lhs: EvidencePiece, rhs: EvidencePiece) -> Bool {
        // Compare IDs for equality since images can't be directly compared
        lhs.id == rhs.id
    }
    
    /// The visual representation of this evidence piece
    public var image: Image? {
        switch type {
        case .system(let name):
            return Image(systemName: name)
        case .custom(let image):
            return image
        case .video:
            // Default video thumbnail
            return Image(systemName: "play.circle.fill")
        }
    }
    
    /// Whether this evidence piece represents a video
    public var isVideo: Bool {
        if case .video = type {
            return true
        }
        return false
    }
    
    /// The video URL if this is a video piece
    public var videoURL: URL? {
        if case .video(let url) = type {
            return url
        }
        return nil
    }
    
    // MARK: - Convenience Initializers
    
    /// Creates a system icon evidence piece
    /// - Parameter name: The SF Symbol name
    public static func system(_ name: String) -> EvidencePiece {
        EvidencePiece(title: name, type: .system(name))
    }
    
    /// Creates a custom image evidence piece
    /// - Parameter image: The custom image
    public static func custom(_ image: Image, title: String = "Title") -> EvidencePiece {
        EvidencePiece(title: title, type: .custom(image))
    }
    
    /// Creates a video evidence piece
    /// - Parameter url: The video URL
    public static func video(_ url: URL, title: String = "Title") -> EvidencePiece {
        EvidencePiece(title: title, type: .video(url))
    }
    
    #if DEBUG
    // Sample pieces for previews and testing
    public static let samplePieces: [EvidencePiece] = [
        EvidencePiece(title: "photo", type: .system("photo"), metadata: ["type": "photo"]),
        EvidencePiece(title: "mountain bike", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
        EvidencePiece(title: "video", type: .video(URL(string: "video.mp4")!), metadata: ["type": "video"]),
        EvidencePiece(title: "document", type: .system("doc.text.image"), metadata: ["type": "document"]),
        EvidencePiece(title: "photo", type: .system("photo.fill"), metadata: ["type": "photo"])
    ]
    #endif
    
    /// Loads and measures the image dimensions
    /// - Returns: True if dimensions were successfully loaded
    public mutating func loadImageDimensions() async -> Bool {
        guard !hasLoadedDimensions else { return true }
        
        switch type {
        case .system(let name):
            // For system images, use a default size
            imageWidth = 1.0
            imageHeight = 1.0
            hasLoadedDimensions = true
            return true
            
        case .custom(let image):
            #if os(iOS)
            // On iOS, convert SwiftUI Image to UIImage
            if let uiImage = image.asUIImage() {
                imageWidth = uiImage.size.width
                imageHeight = uiImage.size.height
                hasLoadedDimensions = true
                return true
            }
            #elseif os(macOS)
            // On macOS, convert SwiftUI Image to NSImage
            if let nsImage = image.asNSImage() {
                imageWidth = nsImage.size.width
                imageHeight = nsImage.size.height
                hasLoadedDimensions = true
                return true
            }
            #endif
            
        case .video(let url):
            // For videos, try to get dimensions from the video file
            do {
                let asset = AVAsset(url: url)
                let tracks = try await asset.loadTracks(withMediaType: .video)
                if let track = tracks.first {
                    let size = try await track.load(.naturalSize)
                    imageWidth = size.width
                    imageHeight = size.height
                    hasLoadedDimensions = true
                    return true
                }
            } catch {
                Self.logger.error("Failed to load video dimensions: \(error.localizedDescription)")
            }
        }
        
        return false
    }
    
    /// Calculates the width for a view displaying this evidence piece
    /// - Parameters:
    ///   - targetHeight: The desired height of the view
    ///   - maxWidth: Optional maximum width constraint
    /// - Returns: The calculated width that maintains the image's aspect ratio
    public func calculateViewWidth(targetHeight: CGFloat, maxWidth: CGFloat? = nil) -> CGFloat {
        // If we have stored dimensions, use them
        if let width = imageWidth, let height = imageHeight {
            let aspectRatio = width / height
            let calculatedWidth = targetHeight * aspectRatio
            return maxWidth.map { min(calculatedWidth, $0) } ?? calculatedWidth
        }
        
        // Fallback to type-specific default aspect ratios
        switch type {
        case .system:
            return targetHeight // Square aspect ratio for system images
        case .video:
            return targetHeight * (16.0/9.0) // 16:9 for videos
        case .custom:
            return targetHeight * (4.0/3.0) // 4:3 for custom images
        }
    }
    
    /// Updates the stored image dimensions
    /// - Parameters:
    ///   - width: The width of the image
    ///   - height: The height of the image
    public mutating func updateImageDimensions(width: CGFloat, height: CGFloat) {
        self.imageWidth = width
        self.imageHeight = height
    }
}

#if os(iOS)
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
#elseif os(macOS)
extension Image {
    func asNSImage() -> NSImage? {
        let controller = NSHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view.frame = CGRect(origin: .zero, size: targetSize)
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        
        guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }
        
        view.cacheDisplay(in: view.bounds, to: bitmapRep)
        
        let image = NSImage(size: targetSize)
        image.addRepresentation(bitmapRep)
        return image
    }
}
#endif

// Logger for debugging
private let logger: Logger = Logger(subsystem: "com.record-thing", category: "ui.checkbox-image-card")

/// ViewModel for managing the state and business logic of RecordedStackAndRequirementsView
/*
    This view model is responsible for managing the state and business logic of the RecordedStackAndRequirementsView.
    - Actions that have been done (for current thing)
    - Actions that have not yet been done (for current thing)
    - Evidence already recorded (for current thing)
    - Most recent evidence (with open questions)
    
*/
@MainActor
public class EvidenceViewModel: ObservableObject {
    // MARK: - Types
    
    // MARK: - Properties
    
    // Published state
    @Published public var checkboxItems: [CheckboxItem]
    @Published public var pieces: [EvidencePiece]
    @Published public var currentPiece: EvidencePiece?
    @Published public var isAnimating: Bool = false
    @Published public var focusMode: Bool = false
    @Published public var reviewing: Bool = false
    
    // Evidence properties
    public var evidenceOptions: [String] {
        get {
            guard let currentPiece = currentPiece,
                  let optionsString = currentPiece.metadata["evidenceOptions"] else {
                return []
            }
            return optionsString.components(separatedBy: "|")
        }
        set {
            guard let currentPiece = currentPiece else { return }
            var metadata = currentPiece.metadata
            metadata["evidenceOptions"] = newValue.joined(separator: "|")
            let updatedPiece = EvidencePiece(currentPiece, metadata: metadata)
            if let index = pieces.firstIndex(where: { $0.id == currentPiece.id }) {
                pieces[index] = updatedPiece
                self.currentPiece = updatedPiece
            }
        }
    }
    
    public var evidenceDecision: String? {
        get {
            currentPiece?.metadata["evidenceDecision"]
        }
        set {
            guard let currentPiece = currentPiece else { return }
            var metadata = currentPiece.metadata
            metadata["evidenceDecision"] = newValue
            let updatedPiece = EvidencePiece(currentPiece, metadata: metadata)
            if let index = pieces.firstIndex(where: { $0.id == currentPiece.id }) {
                pieces[index] = updatedPiece
                self.currentPiece = updatedPiece
            }
        }
    }
    
    public var evidenceTitle: String {
        get {
            currentPiece?.metadata["evidenceTitle"] ?? ""
        }
        set {
            guard let currentPiece = currentPiece else { return }
            var metadata = currentPiece.metadata
            metadata["evidenceTitle"] = newValue
            let updatedPiece = EvidencePiece(currentPiece, metadata: metadata)
            if let index = pieces.firstIndex(where: { $0.id == currentPiece.id }) {
                pieces[index] = updatedPiece
                self.currentPiece = updatedPiece
            }
        }
    }
    
    // Evidence review properties
    @Published public var evidenceReviewImage: RecordImage?
    @Published public var evidenceReviewClip: URL?
    
    // Configuration
    public var direction: EvidenceReview.LayoutDirection
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
    
    // MARK: - Initialization
    
    /// Creates a new EvidenceViewModel
    /// - Parameters:
    ///   - checkboxItems: Array of checkbox items to display
    ///   - pieces: Array of evidence pieces to display in the stack
    ///   - currentPiece: The currently selected evidence piece (defaults to last piece if not specified)
    ///   - direction: Direction of the layout (horizontal or vertical)
    ///   - spacing: Spacing between the checkbox carousel and image stack
    ///   - alignment: Horizontal alignment of the components
    ///   - maxCheckboxItems: Maximum number of checkbox items visible at once
    ///   - designSystem: Design system configuration for styling
    ///   - focusMode: Whether the view is in focus mode
    ///   - reviewing: Mode for full review evidence cards
    public init(
        checkboxItems: [CheckboxItem],
        pieces: [EvidencePiece],
        currentPiece: EvidencePiece? = nil,
        direction: EvidenceReview.LayoutDirection = .horizontal,
        spacing: CGFloat = 2,
        alignment: HorizontalAlignment = .leading,
        maxCheckboxItems: Int = 1,
        checkboxOrientation: CarouselOrientation = .horizontal,
        designSystem: DesignSystemSetup = .light,
        focusMode: Bool = false,
        reviewing: Bool = false
    ) {
        self.checkboxItems = checkboxItems
        self.pieces = pieces
        self.currentPiece = currentPiece ?? pieces.last
        self.direction = direction
        self.spacing = spacing
        self.alignment = alignment
        self.maxCheckboxItems = maxCheckboxItems
        self.designSystem = designSystem
        self.focusMode = focusMode
        self.reviewing = reviewing
        
        // Image stack configuration
        self.showCardBorder = true
        self.cardPlaceholderSystemImage = nil
        
        // Checkbox configuration
        self.checkboxOrientation = checkboxOrientation
        
        logger.debug("EvidenceViewModel initialized with \(checkboxItems.count) checkbox items, \(pieces.count) evidence pieces")
    }
    
    // MARK: - Public Methods
    
    /// Updates the checkbox items
    /// - Parameter newItems: The new checkbox items
    public func updateCheckboxItems(_ newItems: [CheckboxItem]) {
        checkboxItems = newItems
        logger.debug("Updated checkbox items to \(newItems.count) items")
    }
    
    /// Updates the evidence pieces
    /// - Parameter newPieces: The new evidence pieces
    public func updatePieces(_ newPieces: [EvidencePiece]) {
        pieces = newPieces
        // Update currentPiece if it's no longer in the pieces array
        if let current = currentPiece, !newPieces.contains(current) {
            currentPiece = newPieces.last
        }
        logger.debug("Updated evidence pieces to \(newPieces.count) pieces")
    }
    
    /// Sets the current piece to the specified piece
    /// - Parameter piece: The piece to set as current
    /// - Returns: True if the piece was found and set as current, false otherwise
    @discardableResult
    public func setCurrentPiece(_ piece: EvidencePiece) -> Bool {
        guard pieces.contains(piece) else {
            logger.debug("Cannot set current piece: piece not found in pieces array")
            return false
        }
        currentPiece = piece
        logger.debug("Set current piece with ID: \(piece.id)")
        return true
    }
    
    /// Sets the current piece by index
    /// - Parameter index: The index of the piece to set as current
    /// - Returns: True if the index was valid and the piece was set as current, false otherwise
    @discardableResult
    public func setCurrentPiece(at index: Int) -> Bool {
        guard index >= 0 && index < pieces.count else {
            logger.debug("Cannot set current piece: index \(index) out of bounds")
            return false
        }
        currentPiece = pieces[index]
        logger.debug("Set current piece at index: \(index)")
        return true
    }
    
    /// Moves to the next piece in the stack
    /// - Parameter wrap: Whether to wrap around to the first piece when at the end
    /// - Returns: True if successfully moved to the next piece, false otherwise
    @discardableResult
    public func moveToNextPiece(wrap: Bool = true) -> Bool {
        guard !pieces.isEmpty else { return false }
        guard let current = currentPiece, let currentIndex = pieces.firstIndex(of: current) else {
            // If no current piece, set to first piece
            currentPiece = pieces.first
            return true
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < pieces.count {
            currentPiece = pieces[nextIndex]
            logger.debug("Moved to next piece at index: \(nextIndex)")
            return true
        } else if wrap {
            currentPiece = pieces.first
            logger.debug("Wrapped to first piece")
            return true
        }
        return false
    }
    
    /// Moves to the previous piece in the stack
    /// - Parameter wrap: Whether to wrap around to the last piece when at the beginning
    /// - Returns: True if successfully moved to the previous piece, false otherwise
    @discardableResult
    public func moveToPreviousPiece(wrap: Bool = true) -> Bool {
        guard !pieces.isEmpty else { return false }
        guard let current = currentPiece, let currentIndex = pieces.firstIndex(of: current) else {
            // If no current piece, set to last piece
            currentPiece = pieces.last
            return true
        }
        
        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            currentPiece = pieces[previousIndex]
            logger.debug("Moved to previous piece at index: \(previousIndex)")
            return true
        } else if wrap {
            currentPiece = pieces.last
            logger.debug("Wrapped to last piece")
            return true
        }
        return false
    }
    
    /// Replaces the top piece in the evidence stack with a new piece
    /// - Parameter newPiece: The new piece to place on top of the stack
    public func replaceTopPiece(with newPiece: EvidencePiece) {
        guard !pieces.isEmpty else {
            logger.debug("Cannot replace top piece: no pieces in stack")
            return
        }
        
        isAnimating = true
        logger.debug("Starting piece replacement animation")
        
        // Update the pieces after the animation completes
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(0.6 * 1_000_000_000))
            if !pieces.isEmpty {
                var updatedPieces = pieces
                updatedPieces[updatedPieces.count - 1] = newPiece
                pieces = updatedPieces
                // Update currentPiece if it was the replaced piece
                if currentPiece == pieces.last {
                    currentPiece = newPiece
                }
                isAnimating = false
                logger.debug("Completed piece replacement animation")
            }
        }
    }
    
    /// Adds a new piece to the stack
    /// - Parameters:
    ///   - piece: The piece to add
    ///   - setAsCurrent: Whether to set the new piece as the current piece
    public func addPiece(_ piece: EvidencePiece, setAsCurrent: Bool = true) {
        pieces.append(piece)
        if setAsCurrent {
            currentPiece = piece
        }
        logger.debug("Added new piece with ID: \(piece.id)")
    }
    
    /// Removes a piece from the stack
    /// - Parameter piece: The piece to remove
    /// - Returns: True if the piece was found and removed, false otherwise
    @discardableResult
    public func removePiece(_ piece: EvidencePiece) -> Bool {
        guard let index = pieces.firstIndex(of: piece) else {
            logger.debug("Cannot remove piece: piece not found in stack")
            return false
        }
        pieces.remove(at: index)
        // Update currentPiece if removed piece was current
        if currentPiece == piece {
            currentPiece = pieces.last
        }
        logger.debug("Removed piece with ID: \(piece.id)")
        return true
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
    
    // MARK: - Helper Methods
    
    /// Sets evidence options for a piece
    /// - Parameters:
    ///   - options: Array of evidence options
    ///   - piece: The piece to update (defaults to current piece)
    public func setEvidenceOptions(_ options: [String], for piece: EvidencePiece? = nil) {
        let targetPiece = piece ?? currentPiece
        guard var updatingPiece = targetPiece else { return }
        
        var metadata = updatingPiece.metadata
        metadata["evidenceOptions"] = options.joined(separator: "|")
        let updatedPiece = EvidencePiece(
            title: "",
            type: updatingPiece.type,
            metadata: metadata,
            timestamp: updatingPiece.timestamp
        )
        
        if let index = pieces.firstIndex(where: { $0.id == updatingPiece.id }) {
            pieces[index] = updatedPiece
            if targetPiece == currentPiece {
                self.currentPiece = updatedPiece
            }
        }
    }
    
    /// Sets evidence decision for a piece
    /// - Parameters:
    ///   - decision: The decision to set
    ///   - piece: The piece to update (defaults to current piece)
    public func setEvidenceDecision(_ decision: String?, for piece: EvidencePiece? = nil) {
        let targetPiece = piece ?? currentPiece
        guard var updatingPiece = targetPiece else { return }
        
        var metadata = updatingPiece.metadata
        metadata["evidenceDecision"] = decision
        let updatedPiece = EvidencePiece(
            title: "",
            type: updatingPiece.type,
            metadata: metadata,
            timestamp: updatingPiece.timestamp
        )
        
        if let index = pieces.firstIndex(where: { $0.id == updatingPiece.id }) {
            pieces[index] = updatedPiece
            if targetPiece == currentPiece {
                self.currentPiece = updatedPiece
            }
        }
    }
    
    /// Sets evidence title for a piece
    /// - Parameters:
    ///   - title: The title to set
    ///   - piece: The piece to update (defaults to current piece)
    public func setEvidenceTitle(_ title: String, for piece: EvidencePiece? = nil) {
        let targetPiece = piece ?? currentPiece
        guard var updatingPiece = targetPiece else { return }
        
        var metadata = updatingPiece.metadata
        metadata["evidenceTitle"] = title
        let updatedPiece = EvidencePiece(
            title: "",
            type: updatingPiece.type,
            metadata: metadata,
            timestamp: updatingPiece.timestamp
        )
        
        if let index = pieces.firstIndex(where: { $0.id == updatingPiece.id }) {
            pieces[index] = updatedPiece
            if targetPiece == currentPiece {
                self.currentPiece = updatedPiece
            }
        }
    }
    
    #if DEBUG
    /// Creates a default instance of EvidenceViewModel with sample data
    @MainActor public static func createDefault() -> EvidenceViewModel {
        logger.debug("Creating default mocked EvidenceViewModel")
        return EvidenceViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ],
            pieces: [
                EvidencePiece(index: 0, title: "mb1", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 1, title: "mb2", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 2, title: "mb3", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 3, title: "mb4", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 4, title: "DSLR", type: .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module)), metadata: ["type": "photo"])
            ],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay
        )
    }
    
    /// Creates a EvidenceViewModel with custom evidence options
    @MainActor public static func create(evidenceOptions options: [String], evidenceTitle: String = "", evidenceDecision: String? = nil, reviewing: Bool = false) -> EvidenceViewModel {
        logger.debug("Creating mocked EvidenceViewModel with \(options.count) evidence options")
        return EvidenceViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ],
            pieces: [
                EvidencePiece(index: 0, title: "mb1", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 1, title: "mb2", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 2, title: "mb3", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 3, title: "mb4", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 4, title: "DSLR", type: .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module)), metadata: ["type": "photo"])
            ],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay,
            reviewing: true
        )
    }
    
    /// Creates a EvidenceViewModel with custom checkbox items
    @MainActor public static func create(checkboxItems items: [CheckboxItem], checkboxOrientation: CarouselOrientation, direction: EvidenceReview.LayoutDirection = .horizontal, designSystem: DesignSystemSetup = .light) -> EvidenceViewModel {
        logger.debug("Creating mocked EvidenceViewModel with \(items.count) checkbox items")
        return EvidenceViewModel(
            checkboxItems: items,
            pieces: [
                EvidencePiece(index: 0, title: "mb1", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 1, title: "mb2", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 2, title: "mb3", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 3, title: "mb4", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 4, title: "DSLR", type: .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module)), metadata: ["type": "photo"])
            ],
            direction: direction,
            maxCheckboxItems: 1,
            checkboxOrientation: checkboxOrientation,
            designSystem: .cameraOverlay
        )
    }
    
    /// Creates a EvidenceViewModel with custom evidence pieces
    @MainActor public static func create(pieces: [EvidencePiece], reviewing: Bool = false, designSystem: DesignSystemSetup = .light) -> EvidenceViewModel {
        logger.debug("Creating mocked EvidenceViewModel with \(pieces.count) evidence pieces")
        return EvidenceViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ],
            pieces: pieces,
            currentPiece: pieces[0],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay,
            reviewing: reviewing
        )
    }

    #endif
}
