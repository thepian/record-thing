import SwiftUI
import RecordLib
import os

/// A detail panel that shows information about a selected thing
public struct ThingDetailPanel: View {
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.thing-detail")
    
    // Design system
    let designSystem: DesignSystemSetup
    
    // Data
    let thing: Things
    let evidenceViewModel: EvidenceViewModel
    
    // Callbacks
    let onDismiss: () -> Void
    
    // Platform specific
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    /// Creates a new ThingDetailPanel
    /// - Parameters:
    ///   - thing: The thing to display details for
    ///   - evidenceViewModel: View model containing evidence data
    ///   - designSystem: Design system configuration
    ///   - onDismiss: Callback to handle panel dismissal
    public init(
        thing: Things,
        evidenceViewModel: EvidenceViewModel,
        designSystem: DesignSystemSetup = .light,
        onDismiss: @escaping () -> Void
    ) {
        self.thing = thing
        self.evidenceViewModel = evidenceViewModel
        self.designSystem = designSystem
        self.onDismiss = onDismiss
        logger.debug("Initializing ThingDetailPanel for thing: \(thing.title ?? "Untitled")")
    }
    
    public var body: some View {
        #if os(macOS)
        detailContent
            .frame(
                minWidth: platformSpecificMinWidth,
                idealWidth: platformSpecificIdealWidth,
                maxWidth: .infinity
            )
        #else
        ZStack(alignment: .topTrailing) {
            detailContent
            
            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        #endif
    }
    
    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Thing header
                HStack {
                    if let imageName = thing.evidence_type_name {
                        Image(systemName: imageName)
                            .font(.system(size: 30))
                            .foregroundColor(.accentColor)
                    }
                    VStack(alignment: .leading) {
                        Text(thing.title ?? "Untitled")
                            .font(.title2)
                            .fontWeight(.bold)
                        if let category = thing.category {
                            Text(category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(designSystem.cornerRadius)
                
                // Thing details
                if let description = thing.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                // Evidence section
                if !evidenceViewModel.pieces.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Evidence")
                            .font(.headline)
                        /*
                        ForEach(evidenceViewModel.pieces) { piece in
                            HStack {
                                if let imageName = piece.evidence_type_name {
                                    Image(systemName: imageName)
                                        .font(.system(size: 20))
                                        .foregroundColor(.accentColor)
                                }
                                Text(piece.name)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        */
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(designSystem.cornerRadius)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Platform Specific Layout
    
    private var platformSpecificMinWidth: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .regular ? 300 : 200
        #else
        return 300
        #endif
    }
    
    private var platformSpecificIdealWidth: CGFloat {
        #if os(iOS)
        return horizontalSizeClass == .regular ? 400 : 300
        #else
        return 400
        #endif
    }
}

// MARK: - Previews
#if DEBUG
struct ThingDetailPanel_Previews: PreviewProvider {
    static var previews: some View {
        @Previewable @StateObject var evidenceViewModel = EvidenceViewModel.createDefault()
        
        Group {
            ThingDetailPanel(
                thing: .Electronics,
                evidenceViewModel: evidenceViewModel,
                onDismiss: { print("dismissed") }
            )
            .previewDisplayName("Thing Detail Panel")
            
            #if os(iOS)
            ThingDetailPanel(
                thing: .Electronics,
                evidenceViewModel: evidenceViewModel,
                onDismiss: { print("dismissed") }
            )
            .previewDisplayName("Thing Detail Panel - landscape")
            .previewInterfaceOrientation(.landscapeLeft)
            
            ThingDetailPanel(
                thing: .Electronics,
                evidenceViewModel: evidenceViewModel,
                onDismiss: { print("dismissed") }
            )
            .previewDisplayName("Thing Detail Panel - portrait")
            .previewInterfaceOrientation(.portrait)
            #endif
        }
    }
}
#endif 
