/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A card that presents an EvidenceGraphic and allows it to flip over to reveal its nutritional information
*/

import SwiftUI

// MARK: - Ingredient View

struct EvidenceCard: View {
    var evidence: Evidence
    var presenting: Bool
    var closeAction: () -> Void = {}
    
    @State private var visibleSide = FlipViewSide.front
    
    var body: some View {
        FlipView(visibleSide: visibleSide) {
            EvidenceGraphic(evidence: evidence, title: Evidence.CardTitle(), style: presenting ? .cardFront : .thumbnail, closeAction: closeAction, flipAction: flipCard)
        } back: {
            EvidenceGraphic(evidence: evidence, title: Evidence.CardTitle(), style: .cardBack, closeAction: closeAction, flipAction: flipCard)
        }
        .contentShape(Rectangle())
        .animation(.flipCard, value: visibleSide)
    }
    
    func flipCard() {
        visibleSide.toggle()
    }
}


#Preview {
    EvidenceCard(evidence: .avocado, presenting: true)
}
