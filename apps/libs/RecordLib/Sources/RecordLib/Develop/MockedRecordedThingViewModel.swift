import SwiftUI
import os

/// A mock implementation of RecordedThingViewModel for previews and testing
public struct MockedRecordedThingViewModel {
    private static let logger = Logger(subsystem: "com.record-thing", category: "develop.mocked-recorded-thing")
    
    /// Creates a default instance of RecordedThingViewModel with sample data
    @MainActor public static func createDefault() -> RecordedThingViewModel {
        logger.debug("Creating default MockedRecordedThingViewModel")
        return RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ],
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
            ],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay,
            evidenceOptions: [
                "Electric Mountain Bike",
                "Mountain Bike",
                "E-Bike"
            ],
            evidenceReviewImage: RecordImage.named("thepia_a_high-end_electric_mountain_bike_1"),
            onCardStackTapped: {
                logger.debug("Card stack tapped in mock view model")
            }
        )
    }
    
    /// Creates a RecordedThingViewModel with custom evidence options
    @MainActor public static func create(evidenceOptions options: [String]) -> RecordedThingViewModel {
        logger.debug("Creating MockedRecordedThingViewModel with \(options.count) evidence options")
        return RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ],
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
            ],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay,
            evidenceOptions: options,
            evidenceReviewImage: RecordImage.named("thepia_a_high-end_electric_mountain_bike_1"),
            onCardStackTapped: {
                logger.debug("Card stack tapped in mock view model")
            }
        )
    }
    
    /// Creates a RecordedThingViewModel with custom checkbox items
    @MainActor public static func create(checkboxItems items: [CheckboxItem]) -> RecordedThingViewModel {
        logger.debug("Creating MockedRecordedThingViewModel with \(items.count) checkbox items")
        return RecordedThingViewModel(
            checkboxItems: items,
            cardImages: [
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
                .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module))
            ],
            direction: .horizontal,
            maxCheckboxItems: 1,
            designSystem: .cameraOverlay,
            evidenceOptions: [
                "Electric Mountain Bike",
                "Mountain Bike",
                "E-Bike"
            ],
            evidenceReviewImage: RecordImage.named("thepia_a_high-end_electric_mountain_bike_1"),
            onCardStackTapped: {
                logger.debug("Card stack tapped in mock view model")
            }
        )
    }
} 
