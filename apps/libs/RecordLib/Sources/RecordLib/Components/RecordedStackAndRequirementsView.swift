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
        logger.debug("RecordedStackAndRequirementsView initialized with view model")
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
    }
    
    // MARK: - UI Components
    
    /// Horizontal layout with checkbox on left, images on right
    private var horizontalLayout: some View {
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
    
    /// Vertical layout with checkbox on top, images on bottom
    private var verticalLayout: some View {
        VStack(alignment: viewModel.alignment, spacing: viewModel.spacing) {
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
    
    /// Checkbox carousel component
    private var checkboxCarousel: some View {
        CheckboxCarouselView(viewModel: viewModel)
    }
    
    /// Image card stack component
    private var imageCardStack: some View {
        ImageCardStack(viewModel: viewModel)
    }
}

// MARK: - Preview

struct CheckboxImageCardView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var viewModel = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take a photo of the product"),
                CheckboxItem(text: "Scan the barcode", isChecked: true),
                CheckboxItem(text: "Capture the receipt"),
                CheckboxItem(text: "Add product details")
            ],
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
            ],
            direction: .horizontal,
            designSystem: DesignSystemSetup(
                textColor: .primary,
                accentColor: .blue,
                backgroundColor: .white,
                borderColor: .gray.opacity(0.2),
                shadowColor: .black.opacity(0.1)
            ),
            onCardStackTapped: {
                print("Card stack tapped")
            }
        )
        
        @StateObject var viewModel2 = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "First item"),
                CheckboxItem(text: "Second item", isChecked: true)
            ],
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
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
        
        @StateObject var viewModel3 = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Dark mode item 1"),
                CheckboxItem(text: "Dark mode item 2")
            ],
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
            ],
            designSystem: DesignSystemSetup(
                textColor: .white,
                accentColor: .white,
                backgroundColor: .black,
                borderColor: .white.opacity(0.2),
                shadowColor: .white.opacity(0.3)
            )
        )

        Group {
            // Horizontal layout with titles
            RecordedStackAndRequirementsView(
                viewModel: viewModel
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Horizontal with Titles")
            
            // Vertical layout with custom styling
            RecordedStackAndRequirementsView(
                viewModel: viewModel2
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Vertical with Custom Styling")
            
            // Dark mode preview
            RecordedStackAndRequirementsView(
                viewModel: viewModel3
            )
            .previewLayout(.sizeThatFits)
            .background(Color.black)
            .previewDisplayName("Dark Mode")
        }
    }
}
