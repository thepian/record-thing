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
///     viewModel: RecordedThingViewModel(
///         checkboxItems: [
///             CheckboxItem(text: "Take a photo"),
///             CheckboxItem(text: "Scan barcode", isChecked: true),
///             CheckboxItem(text: "Add details")
///         ],
///         cardImages: [
///             .system("photo"),
///             .system("camera"),
///             .system("doc.text.image")
///         ]
///     )
/// )
/// ```
public struct RecordedStackAndRequirementsView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.checkbox-image-card")
    
    // ViewModel
    @StateObject private var viewModel: RecordedThingViewModel
    
    // MARK: - Types
    
    /// Direction of the layout
    public enum LayoutDirection {
        case horizontal  // Checkbox on left, images on right
        case vertical    // Checkbox on top, images on bottom
    }
    
    // MARK: - Initialization
    
    /// Creates a new CheckboxImageCardView
    /// - Parameter viewModel: The view model that manages the state and business logic
    public init(viewModel: RecordedThingViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        logger.trace("RecordedStackAndRequirementsView initialized with view model")
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if viewModel.direction == .horizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
        .onAppear {
            // Add observer for exit reviewing mode notification
            NotificationCenter.default.addObserver(
                forName: .exitReviewingMode,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    viewModel.reviewing = false
                }
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            NotificationCenter.default.removeObserver(self)
        }
//        .gesture(
//            DragGesture(minimumDistance: 20)
//                .onEnded { value in
//                    let verticalMovement = value.translation.height
//                    let threshold: CGFloat = 50 // Minimum swipe distance to trigger
//                    
//                    withAnimation(.spring()) {
//                        if viewModel.reviewing && verticalMovement > threshold {
//                            // Swipe down to collapse
//                            viewModel.reviewing = false
//                        }
//                    }
//                }
//        )
    }
    
    // MARK: - UI Components
    
    /// Horizontal layout with checkbox on left, images on right
    private var horizontalLayout: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Spacer()
                if viewModel.reviewing {
                    Carousel(cards: viewModel.pieces, designSystem: viewModel.designSystem)
                        .frame(width: viewModel.designSystem.evidenceReviewWidth)
                    HStack(alignment: .center, spacing: viewModel.spacing) {
                        Spacer()
                        
                        // Image stack section
                        VStack(alignment: viewModel.alignment) {
                            imageCardStack
                                .grayscale(1.0)
                                .contrast(0.75)
//                                .brightness(-0.2)
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: viewModel.spacing) {
                        // Checkbox section
                        VStack(alignment: viewModel.alignment) {
                            checkboxCarousel
                        }
                        
                        // Image stack section
                        VStack(alignment: viewModel.alignment) {
                            imageCardStack
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    /// Vertical layout with checkbox on top, images on bottom
    private var verticalLayout: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Spacer()
                if viewModel.reviewing {
                    Spacer()
                    Carousel(cards: viewModel.pieces, designSystem: viewModel.designSystem)
                        .frame(width: viewModel.designSystem.evidenceReviewWidth)
                    Spacer()
                } else {
                    // Checkbox section
                    VStack(alignment: viewModel.alignment) {
                        checkboxCarousel
                    }
                    
                    // Image stack section
                    VStack(alignment: viewModel.alignment) {
                        imageCardStack
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    /// Checkbox carousel component
    private var checkboxCarousel: some View {
        CheckboxCarouselView(viewModel: viewModel)
    }
    
    /// Image card stack component
    private var imageCardStack: some View {
        ImageCardStack(viewModel: viewModel)
            .onTapGesture {
                withAnimation(.spring()) {
                    viewModel.reviewing.toggle()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let verticalMovement = value.translation.height
                        let threshold: CGFloat = 50 // Minimum swipe distance to trigger
                        
                        withAnimation(.spring()) {
                            if !viewModel.reviewing && verticalMovement < -threshold {
                                // Swipe up to expand
                                viewModel.reviewing = true
                            } else if viewModel.reviewing && verticalMovement > threshold {
                                // Swipe down to collapse
                                viewModel.reviewing = false
                            }
                        }
                    }
            )
    }
}

// MARK: - Preview

struct CheckboxImageCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Horizontal layout with titles
            RecordedStackAndRequirementsView(
                viewModel: MockedRecordedThingViewModel.create(
                    checkboxItems: [
                        CheckboxItem(text: "Take a photo of the product"),
                        CheckboxItem(text: "Scan the barcode", isChecked: true),
                        CheckboxItem(text: "Capture the receipt"),
                        CheckboxItem(text: "Add product details")
                    ],
                    direction: .horizontal,
                    designSystem: DesignSystemSetup(
                        textColor: .primary,
                        accentColor: .blue,
                        backgroundColor: .white,
                        borderColor: .gray.opacity(0.2),
                        shadowColor: .black.opacity(0.1)
                    )
                )
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Horizontal with Titles")
            
            // Horizontal layout with titles
            RecordedStackAndRequirementsView(
                viewModel: MockedRecordedThingViewModel.create(
                    pieces: [
                        EvidencePiece(index: 0, title: "mb1", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                        EvidencePiece(index: 1, title: "mb2", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                        EvidencePiece(index: 2, title: "mb3", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                        EvidencePiece(index: 3, title: "mb4", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                        EvidencePiece(index: 4, title: "DSLR", type: .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module)), metadata: ["type": "photo"])
                    ],
                    reviewing: true,
                    designSystem: DesignSystemSetup(
                        textColor: .primary,
                        accentColor: .blue,
                        backgroundColor: .white,
                        borderColor: .gray.opacity(0.2),
                        shadowColor: .black.opacity(0.1)
                    )
                )
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Reviewing")
            
            // Vertical layout with custom styling
            RecordedStackAndRequirementsView(
                viewModel: MockedRecordedThingViewModel.create(
                    checkboxItems: [
                        CheckboxItem(text: "First item"),
                        CheckboxItem(text: "Second item", isChecked: true)
                    ],
                    direction: .vertical,
                    designSystem: DesignSystemSetup(
                        textColor: .blue,
                        accentColor: .orange,
                        backgroundColor: .white,
                        borderColor: .orange.opacity(0.3),
                        shadowColor: .orange.opacity(0.2),
                        cardSize: 50,
                        cardRotation: 5
                    )
                )
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Vertical with Custom Styling")
            
            // Dark mode preview
            RecordedStackAndRequirementsView(
                viewModel: MockedRecordedThingViewModel.create(
                    checkboxItems: [
                        CheckboxItem(text: "Dark mode item 1"),
                        CheckboxItem(text: "Dark mode item 2")
                    ],
                    direction: .vertical,
                    designSystem: DesignSystemSetup(
                        textColor: .white,
                        accentColor: .white,
                        backgroundColor: .black,
                        borderColor: .white.opacity(0.2),
                        shadowColor: .white.opacity(0.3)
                    )
                )
            )
            .previewLayout(.sizeThatFits)
            .background(Color.black)
            .previewDisplayName("Dark Mode")
        }
    }
}
