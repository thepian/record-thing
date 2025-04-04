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
    
    /// Creates a RecordedThingViewModel with custom evidence options
    @MainActor public static func create(evidenceOptions options: [String], evidenceTitle: String = "", evidenceDecision: String? = nil, reviewing: Bool = false) -> RecordedThingViewModel {
        logger.debug("Creating MockedRecordedThingViewModel with \(options.count) evidence options")
        return RecordedThingViewModel(
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
    
    /// Creates a RecordedThingViewModel with custom checkbox items
    @MainActor public static func create(checkboxItems items: [CheckboxItem], direction: RecordedStackAndRequirementsView.LayoutDirection = .horizontal, designSystem: DesignSystemSetup = .light) -> RecordedThingViewModel {
        logger.debug("Creating MockedRecordedThingViewModel with \(items.count) checkbox items")
        return RecordedThingViewModel(
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
            designSystem: .cameraOverlay
        )
    }
    
    /// Creates a RecordedThingViewModel with custom evidence pieces
    @MainActor public static func create(pieces: [EvidencePiece], reviewing: Bool = false, designSystem: DesignSystemSetup = .light) -> RecordedThingViewModel {
        logger.debug("Creating MockedRecordedThingViewModel with \(pieces.count) evidence pieces")
        return RecordedThingViewModel(
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
} 
