/*
See LICENSE folder for this sample's licensing information.

Abstract:
A card that presents an EvidenceGraphic and allows it to flip over to reveal its nutritional information
*/

import SwiftUI


// MARK: - Ingredient View

public struct EvidenceCard: View {
    public var evidence: Evidence
    public var presenting: Bool
    public var closeAction: () -> Void = {}
    
    @State private var visibleSide = FlipViewSide.front
    
    public init(evidence: Evidence, presenting: Bool, closeAction: @escaping () -> Void = {}) {
        self.evidence = evidence
        self.presenting = presenting
        self.closeAction = closeAction
    }
    
    public var body: some View {
        FlipView(visibleSide: visibleSide) {
            EvidenceGraphic(evidence: evidence, title: Evidence.CardTitle(), style: presenting ? .cardFront : .thumbnail, closeAction: closeAction, flipAction: flipCard)
        } back: {
            EvidenceGraphic(evidence: evidence, title: Evidence.CardTitle(), style: .cardBack, closeAction: closeAction, flipAction: flipCard)
        }
        .contentShape(Rectangle())
        .animation(.flipCard, value: visibleSide)
    }
    
    public func flipCard() {
        visibleSide.toggle()
    }
}


#Preview {
    Text(LocalizedStringKey("Evidence.recipe"))
    EvidenceCard(evidence: .avocado, presenting: true)
}
