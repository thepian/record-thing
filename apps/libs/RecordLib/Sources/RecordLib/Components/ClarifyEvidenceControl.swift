import SwiftUI
import os

/// A control that cycles through evidence options and allows users to confirm or deny each option
public struct ClarifyEvidenceControl: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.clarify-evidence")
    
    // ViewModel
    @ObservedObject private var viewModel: RecordedThingViewModel
    private let designSystem: DesignSystemSetup
    let useGlowEffect: Bool = true
    
    // Callback
    private let onOptionConfirmed: ((String) -> Void)?
    
    // State
    @State private var currentOptionIndex: Int = 0
    @State private var deniedOptions: Set<String> = []
    @State private var isTransitioning: Bool = false
        
    // MARK: - Initialization
    
    /// Creates a new ClarifyEvidenceControl
    /// - Parameters:
    ///   - viewModel: The view model that manages the state
    ///   - onOptionConfirmed: Callback when an evidence option is confirmed
    public init(
        viewModel: RecordedThingViewModel,
        onOptionConfirmed: ((String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        designSystem = viewModel.designSystem
        self.onOptionConfirmed = onOptionConfirmed ?? { option in
            viewModel.evidenceTitle = option
        }
        logger.trace("ClarifyEvidenceControl initialized with view model")
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if !viewModel.evidenceTitle.isEmpty {
                // Show title if available
                Text(viewModel.evidenceTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(designSystem.textColor ?? designSystem.dynamicTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .shadow(color: useGlowEffect ? designSystem.glowColor.opacity(designSystem.glowOpacity) : .clear,
                            radius: designSystem.glowRadius,
                            x: 0,
                            y: 0)
                    .padding(EdgeInsets(top: 0, leading: 12, bottom: 32, trailing: 12))
            } else if let currentOption = currentOption {
                // Show cycling options if no title
                SimpleConfirmDenyStatement(
                    objectName: currentOption,
                    onConfirm: { handleConfirm(currentOption) },
                    onDeny: { handleDeny(currentOption) }
                )
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 32, trailing: 12))
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentOptionIndex)
            } else {
                // Maintain height when no options are shown
                Color.clear
                    .frame(height: 100) // Adjust height as needed
            }
        }
        .onAppear {
            startCycling()
        }
        .onChange(of: viewModel.evidenceOptions) { _ in
            // Reset state when options change
            currentOptionIndex = 0
            deniedOptions.removeAll()
            startCycling()
        }
        .onChange(of: viewModel.evidenceTitle) { _ in
            // Reset state when title changes
            currentOptionIndex = 0
            deniedOptions.removeAll()
            if viewModel.evidenceTitle.isEmpty {
                startCycling()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// The current evidence option to display
    private var currentOption: String? {
        // If we have a decision, don't show anything
        if viewModel.evidenceDecision != nil {
            return nil
        }
        
        // Get the next non-denied option
        let availableOptions = viewModel.evidenceOptions.filter { !deniedOptions.contains($0) }
        guard !availableOptions.isEmpty else {
            return nil
        }
        
        return availableOptions[currentOptionIndex % availableOptions.count]
    }
    
    // MARK: - Helper Methods
    
    /// Starts cycling through available options
    private func startCycling() {
        // Only cycle if we have options and no decision has been made
        guard !viewModel.evidenceOptions.isEmpty && viewModel.evidenceDecision == nil else {
            return
        }
        
        // Schedule the next transition
        scheduleNextTransition()
    }
    
    /// Schedules the next transition to a new option
    private func scheduleNextTransition() {
        // Only proceed if we have options and no decision has been made
        guard let _ = currentOption, viewModel.evidenceDecision == nil else {
            return
        }
        
        // Schedule the next transition after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation {
                currentOptionIndex += 1
            }
            scheduleNextTransition()
        }
    }
    
    /// Handles confirmation of an evidence option
    private func handleConfirm(_ option: String) {
        logger.debug("Confirmed evidence option: \(option)")
        viewModel.evidenceDecision = option
        onOptionConfirmed?(option)
        deniedOptions.removeAll()
    }
    
    /// Handles denial of an evidence option
    private func handleDeny(_ option: String) {
        logger.debug("Denied evidence option: \(option)")
        deniedOptions.insert(option)
        withAnimation {
            currentOptionIndex += 1
        }
        scheduleNextTransition()
    }
}

// MARK: - Preview
#if DEBUG
struct ClarifyEvidenceControl_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Preview with title
            ClarifyEvidenceControl(
                viewModel: MockedRecordedThingViewModel.create(
                    evidenceOptions: [],
                    evidenceTitle: "Electric Mountain Bike"
                )
            )
        }
        .previewDisplayName("With Title")

        VStack {
            // Preview with options
            ClarifyEvidenceControl(
                viewModel: MockedRecordedThingViewModel.create(
                    evidenceOptions: [
                        "Electric Mountain Bike",
                        "Mountain Bike",
                        "E-Bike"
                    ]
                )
            )
        }
        .previewDisplayName("With Options")
         
        VStack {
            // Preview with decision
            ClarifyEvidenceControl(
                viewModel: MockedRecordedThingViewModel.create(
                    evidenceOptions: [
                        "Electric Mountain Bike",
                        "Mountain Bike",
                        "E-Bike"
                    ],
                    evidenceDecision: "Electric Mountain Bike"
                )
            )
        }
        .previewDisplayName("With Decision")
         
        VStack {
            // Preview with no options
            ClarifyEvidenceControl(
                viewModel: MockedRecordedThingViewModel.create(
                    evidenceOptions: []
                )
            )
        }
        .padding()
        .previewDisplayName("No Options")
    }
} 
#endif

