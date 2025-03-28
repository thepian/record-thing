import SwiftUI
import os

/// A view that displays evidence (image or video) in an overlay with proper scaling and borders
public struct EvidenceReview: View {
    @Environment(\.cameraViewModel) var cameraViewModel: CameraViewModel?
    @ObservedObject var viewModel: RecordedThingViewModel
    
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.evidence-review")

    public let designSystem: DesignSystemSetup
    
    // MARK: - Initialization
    
    /// Creates a new EvidenceReview view
    /// - Parameter viewModel: The view model containing the evidence to display
    public init(viewModel: RecordedThingViewModel) {
        self.viewModel = viewModel
        self.designSystem = viewModel.designSystem
        logger.trace("EvidenceReview initialized")
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Evidence content
                if let image = viewModel.evidenceReviewImage {
                    image.asImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: designSystem.evidenceReviewWidth, height: designSystem.evidenceReviewHeight)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(radius: 10)
                } else if let clip = viewModel.evidenceReviewClip {
                    // TODO: Implement video clip playback
                    Text("Video clip playback not yet implemented")
                        .foregroundColor(.white)
                } else {
                    Text("No evidence to review")
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: designSystem.screenWidth, height: designSystem.screenHeight)
        .onAppear {
            logger.debug("EvidenceReview appeared with \(viewModel.evidenceReviewImage != nil ? "image" : "no image") and \(viewModel.evidenceReviewClip != nil ? "clip" : "no clip")")
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct EvidenceReview_Previews: PreviewProvider {
    private static let logger = Logger(subsystem: "com.record-thing", category: "EvidenceReview_Previews")
    
    static var previews: some View {
        Group {
            // Preview with image
            EvidenceReview(viewModel: MockedRecordedThingViewModel.createDefault())
                .previewDisplayName("With Image")
            
            // Preview without evidence
            EvidenceReview(viewModel: MockedRecordedThingViewModel.create(evidenceOptions: []))
                .previewDisplayName("No Evidence")
        }
    }
}
#endif 
