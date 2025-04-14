/*
See LICENSE folder for this sample's licensing information.

Abstract:
A graphic that displays an Evidence as a thumbnail, a card highlighting its image, or the back of a card highlighting its nutrition facts.
*/

import SwiftUI
import RecordLib

public struct EvidenceGraphic: View {
    public var evidence: Evidence
    public var title: Evidence.CardTitle
    public var style: Style
    public var closeAction: () -> Void = {}
    public var flipAction: () -> Void = {}
    
    public var thumbnailCrop = Evidence.Crop()
    public var cardCrop = Evidence.Crop()
    
    public enum Style {
        case cardFront
        case cardBack
        case thumbnail
    }
    
    public init(
        evidence: Evidence,
        title: Evidence.CardTitle = Evidence.CardTitle(),
        style: Style,
        closeAction: @escaping () -> Void = {},
        flipAction: @escaping () -> Void = {},
        thumbnailCrop: Evidence.Crop = Evidence.Crop(),
        cardCrop: Evidence.Crop = Evidence.Crop()
    ) {
        self.evidence = evidence
        self.title = title
        self.style = style
        self.closeAction = closeAction
        self.flipAction = flipAction
        self.thumbnailCrop = thumbnailCrop
        self.cardCrop = cardCrop
    }
    
    public var displayingAsCard: Bool {
        style == .cardFront || style == .cardBack
    }
    
    public var shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
    
    public var body: some View {
        ZStack {
            imageView
            if style != .cardBack {
                titleView
            }
            
            if style == .cardFront {
                cardControls(for: .front)
                    .foregroundStyle(title.color)
                    .opacity(title.opacity)
                    .blendMode(title.blendMode)
            }
            
            if style == .cardBack {
                ZStack {
//                    if let nutritionFact = evidence.nutritionFact {
//                        NutritionFactView(nutritionFact: nutritionFact)
//                            .padding(.bottom, 70)
//                    }
//                    cardControls(for: .back)
                }
                .background(.thinMaterial)
            }
        }
        .frame(minWidth: 130, maxWidth: 400, maxHeight: 500)
        .compositingGroup()
        .clipShape(shape)
        .overlay {
            shape
                .inset(by: 0.5)
                .stroke(.quaternary, lineWidth: 0.5)
        }
        .contentShape(shape)
        .accessibilityElement(children: .contain)
    }
    
    public var imageView: some View {
        GeometryReader { geo in
            evidence.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(displayingAsCard ? cardCrop.scale : thumbnailCrop.scale)
                .offset(displayingAsCard ? cardCrop.offset : thumbnailCrop.offset)
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(x: style == .cardBack ? -1 : 1)
        }
        .accessibility(hidden: true)
    }
    
    public var titleView: some View {
        Text(evidence.name.uppercased())
        /*
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .foregroundStyle(title.color)
            .rotationEffect(displayingAsCard ? title.rotation: .degrees(0))
            .opacity(title.opacity)
            .blendMode(title.blendMode)
//            .animatableFont(size: displayingAsCard ? title.fontSize : 40, weight: .bold)
//            .minimumScaleFactor(0.25)
//            .offset(displayingAsCard ? title.offset : .zero)
         */
    }
    
    public func cardControls(for side: FlipViewSide) -> some View {
        VStack {
            if side == .front {
                CardActionButton(label: "Close", systemImage: "xmark.circle.fill", action: closeAction)
                    .scaleEffect(displayingAsCard ? 1 : 0.5)
                    .opacity(displayingAsCard ? 1 : 0)
            }
            Spacer()
            CardActionButton(
                label: side == .front ? "Open Nutrition Facts" : "Close Nutrition Facts",
                systemImage: side == .front ? "info.circle.fill" : "arrow.left.circle.fill",
                action: flipAction
            )
            .scaleEffect(displayingAsCard ? 1 : 0.5)
            .opacity(displayingAsCard ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Previews

struct EvidenceGraphic_Previews: PreviewProvider {
    static let evidence = Evidence.orange
    static var previews: some View {
        Group {
            EvidenceGraphic(evidence: evidence, title: Evidence.CardTitle(), style: .thumbnail)
                .frame(width: 180, height: 180)
                .previewDisplayName("Thumbnail")
            
            EvidenceGraphic(evidence: evidence,  title: Evidence.CardTitle(), style: .cardFront)
                .aspectRatio(0.75, contentMode: .fit)
                .frame(width: 500, height: 600)
                .previewDisplayName("Card Front")

            EvidenceGraphic(evidence: evidence,  title: Evidence.CardTitle(), style: .cardBack)
                .aspectRatio(0.75, contentMode: .fit)
                .frame(width: 500, height: 600)
                .previewDisplayName("Card Back")
        }
        .previewLayout(.sizeThatFits)
    }
}
