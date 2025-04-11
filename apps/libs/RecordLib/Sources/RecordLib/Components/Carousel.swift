//
//  Carousel.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 07.04.2025.
//
import SwiftUI
import os

// MARK: - Gesture State

enum GestureState {
    case idle
    case dragging(translation: CGSize, velocity: CGSize)
    case decelerating(velocity: CGSize)
    case settling
    case exiting
}

// MARK: - CardViewData Implementation

// MARK: - Carousel Implementation

struct Carousel<CVD: CardViewData>: View {
    // MARK: - Properties
    
    @State private var currentIndex: Int = 0
    @State private var gestureState: GestureState = .idle
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var exitProgress: CGFloat = 0.0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let designSystem: DesignSystemSetup
    @State var cards: [CVD]
    
    // MARK: - Constants
    
    private let minimumDragDistance: CGFloat = 20
    private let swipeThreshold: CGFloat = 50
    private let exitAngle: CGFloat = .pi / 4 // 45 degrees
    private let maxOverscroll: CGFloat = 0.3
    
    // MARK: - Card Dimensions
    
    private var cardHeight: CGFloat {
        let baseHeight = designSystem.evidenceReviewHeight
        // Adjust height based on size class
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            // iPhone portrait
            return baseHeight * 0.8
        } else if horizontalSizeClass == .regular && verticalSizeClass == .compact {
            // iPhone landscape
            return baseHeight * 0.6
        } else if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            // iPad
            return baseHeight * 0.9
        }
        return baseHeight
    }
    
    private var cardSpacing: CGFloat {
        designSystem.cardSpacing
    }
    
    // MARK: - Initialization
    
    init(cards: [CVD], designSystem: DesignSystemSetup = .light) {
        self.cards = cards
        self.designSystem = designSystem
    }
    
    // TODO onCollapse - called on completed drag down. Is set to reviewing = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center) {
            GeometryReader { geometry in
                ZStack {
                    ForEach(cards) { card in
                        CardView(
                            card: card,
                            currentIndex: $currentIndex,
                            geometry: geometry,
                            designSystem: designSystem,
                            gestureState: gestureState,
                            exitProgress: exitProgress
                        )
                        .offset(x: calculateCardOffset(
                            for: card,
                            in: geometry,
                            with: dragOffset
                        ).width)
                        .offset(y: calculateCardOffset(
                            for: card,
                            in: geometry,
                            with: dragOffset
                        ).height)
                        .scaleEffect(calculateCardScale(for: card))
                        .opacity(calculateCardOpacity(for: card))
                        .rotationEffect(calculateCardRotation(for: card))
                        .zIndex(card._index == currentIndex ? 1 : 0)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: minimumDragDistance)
                        .onChanged { value in
                            handleDragChanged(value, in: geometry)
                        }
                        .onEnded { value in
                            handleDragEnded(value, in: geometry)
                        }
                )
            }
        }
        .frame(width: designSystem.evidenceReviewWidth, height: designSystem.evidenceReviewHeight)
        
        CarouselPageControl(index: $currentIndex, maxIndex: ((cards.count > 1) ? (cards.count - 1) : 0))
            .padding(EdgeInsets(top: designSystem.cardSpacing, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Gesture Handlers
    
    private func handleDragChanged(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let translation = value.translation
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )
        
        withAnimation(.interactiveSpring()) {
            gestureState = .dragging(translation: translation, velocity: velocity)
            dragOffset = translation
            
            // Calculate exit progress based on vertical movement
            if translation.height > 0 {
                exitProgress = min(translation.height / (geometry.size.height * 0.5), 1.0)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )
        
        // Check if we should exit
        if value.translation.height > swipeThreshold {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                gestureState = .exiting
                exitProgress = 1.0
                
                // Calculate exit trajectory
                let distance = sqrt(pow(geometry.size.width, 2) + pow(geometry.size.height, 2))
                dragOffset = CGSize(
                    width: distance * cos(exitAngle),
                    height: distance * sin(exitAngle)
                )
                
                // Notify parent to exit reviewing mode
                NotificationCenter.default.post(name: .exitReviewingMode, object: nil)
            }
        } else if abs(value.translation.width) > swipeThreshold {
            // Handle horizontal swipe
            withAnimation(.spring()) {
                if value.translation.width < -swipeThreshold {
                    currentIndex = min(currentIndex + 1, cards.count - 1)
                } else if value.translation.width > swipeThreshold {
                    currentIndex = max(currentIndex - 1, 0)
                }
                gestureState = .settling
                dragOffset = .zero
                exitProgress = 0.0
            }
        } else {
            // Return to idle state
            withAnimation(.spring()) {
                gestureState = .settling
                dragOffset = .zero
                exitProgress = 0.0
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateCardOffset(for card: CVD, in geometry: GeometryProxy, with dragOffset: CGSize) -> CGSize {
        let baseOffset = CGFloat(card._index - currentIndex) * (geometry.size.width + 8)
        
        switch gestureState {
        case .idle, .settling:
            return CGSize(width: baseOffset, height: 0)
        case .dragging(let translation, _):
            return CGSize(
                width: baseOffset + translation.width,
                height: translation.height
            )
        case .decelerating(let velocity):
            return CGSize(
                width: baseOffset + dragOffset.width,
                height: dragOffset.height
            )
        case .exiting:
            return dragOffset
        }
    }
    
    private func calculateCardScale(for card: CVD) -> CGFloat {
        let baseScale: CGFloat = card._index == currentIndex ? 1.0 : 0.9
        
        switch gestureState {
        case .dragging:
            return baseScale * 0.95
        case .exiting:
            return baseScale * (1.0 - (exitProgress * 0.2))
        default:
            return baseScale
        }
    }
    
    private func calculateCardOpacity(for card: CVD) -> Double {
        let baseOpacity: Double = card._index <= currentIndex + 1 ? 1.0 : 0.0
        
        switch gestureState {
        case .exiting:
            return baseOpacity * (1.0 - exitProgress)
        default:
            return baseOpacity
        }
    }
    
    private func calculateCardRotation(for card: CVD) -> Angle {
        switch gestureState {
        case .exiting:
            return .degrees(Double(exitProgress * 15))
        default:
            return .degrees(0)
        }
    }
}

// MARK: - CardView

extension Carousel {
    struct CardView: View {
        let card: any CardViewData
        @Binding var currentIndex: Int
        let geometry: GeometryProxy
        let designSystem: DesignSystemSetup
        let gestureState: GestureState
        let exitProgress: CGFloat
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        
        var body: some View {
            let cardHeight = calculateHeight()
            let cardWidth = calculateWidth(height: cardHeight)
            let cornerRadius = designSystem.cornerRadius * 2

            ZStack {
                if let image = card.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .cornerRadius(cornerRadius)
                        .padding(10)
                } else {
                    card.color
                        .frame(width: cardWidth, height: cardHeight)
                }
                
                // Title overlay
                VStack {
                    Spacer()
                    HStack {
                        Text(card.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                            .padding(.horizontal, 22)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
//                        Text("w: \(card.imageWidth ?? 0)")
//                            .font(.system(size: 12))
//                            .foregroundColor(.white.opacity(0.8))
                        
                    }
//                    .background(
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                .black.opacity(0.7),
//                                .black.opacity(0.5)
//                            ]),
//                            startPoint: .bottom,
//                            endPoint: .top
//                        )
//                    )
                    .clipped()
                }
                #if os(iOS)
                .cornerRadius(cornerRadius, corners: [.bottomLeft, .bottomRight])
                #endif
                .clipped()
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipped()
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.white, lineWidth: 3))
        }
        
        private func calculateHeight() -> CGFloat {
            let baseHeight = designSystem.evidenceReviewHeight
            // Adjust height based on size class
            if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                // iPhone portrait
                return baseHeight * 0.8
            } else if horizontalSizeClass == .regular && verticalSizeClass == .compact {
                // iPhone landscape
                return baseHeight * 0.6
            } else if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                // iPad
                return baseHeight * 0.9
            }
            return baseHeight
        }
        
        private func calculateWidth(height: CGFloat) -> CGFloat {
            // If we have image dimensions, use them to maintain aspect ratio
            if let width = card.imageWidth, let height = card.imageHeight {
                let aspectRatio = width / height
                return height * aspectRatio
            }
            
            // Default width based on size class
            if horizontalSizeClass == .compact && verticalSizeClass == .regular {
                // iPhone portrait
                return designSystem.evidenceReviewWidth * 0.9
            } else if horizontalSizeClass == .regular && verticalSizeClass == .compact {
                // iPhone landscape
                return designSystem.evidenceReviewWidth * 0.7
            } else if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                // iPad
                return designSystem.evidenceReviewWidth * 0.85
            }
            
            return designSystem.evidenceReviewWidth
        }
    }
}

struct CarouselPageControl: View {
    @Binding var index: Int
    let maxIndex: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0...maxIndex, id: \.self) { index in
                if index == self.index {
                    Capsule()
                        .fill(.red.opacity(0.7))
                        .frame(width: 8, height: 4)
                        .animation(Animation.spring().delay(0.5), value: index)
                } else {
                    Circle()
                        .fill(.gray.opacity(0.6))
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}

// Add notification extension for exit reviewing mode
extension Notification.Name {
    static let exitReviewingMode = Notification.Name("exitReviewingMode")
}

#if DEBUG
struct ExampleCardViewData: CardViewData {
    let id: UUID
    let _index: Int
    let title: String
    let image: Image?
    let color: Color
    var imageWidth: CGFloat?
    var imageHeight: CGFloat?
    var hasLoadedDimensions: Bool = false
    
    init(id: UUID = UUID(), index: Int, title: String, color: Color = .red, imageName: String? = nil) {
        // "thepia_a_high-end_electric_mountain_bike_1"
        self.id = id
        self._index = index
        self.title = title
        if let imageName = imageName {
            let image = Image(imageName, bundle: Bundle.module)
            self.image = image
            #if os(iOS)
            // On iOS, convert SwiftUI Image to UIImage
            if let uiImage = image.asUIImage() {
                imageWidth = uiImage.size.width
                imageHeight = uiImage.size.height
                hasLoadedDimensions = true
            }
            #elseif os(macOS)
            // On macOS, convert SwiftUI Image to NSImage
            if let nsImage = self.image?.asNSImage() {
                imageWidth = nsImage.size.width
                imageHeight = nsImage.size.height
                hasLoadedDimensions = true
            }
            #endif
        } else {
            self.image = nil
        }
        self.color = color
    }
}


struct Carousel_Previews: PreviewProvider {
    private static let logger = Logger(subsystem: "com.record-thing", category: "Carousel_Previews")
    
    static var previews: some View {
        VStack {
            Carousel(cards: [
                EvidencePiece(index: 0, title: "mb1", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 1, title: "mb2", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 2, title: "mb3", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 3, title: "mb4", type: .custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)), metadata: ["type": "photo"]),
                EvidencePiece(index: 4, title: "DSLR", type: .custom(Image("beige_kitchen_table_with_a_professional_DSLR_standing", bundle: Bundle.module)), metadata: ["type": "photo"])

            ], designSystem: .light)
        }
        .background(Color.gray)
        .previewDisplayName("evidence")
            
        ZStack {
            Carousel(
                cards: [
                    ExampleCardViewData(index: 0, title: "Design One", color: .red),
                    ExampleCardViewData(index: 1, title: "Design Two", color: .blue),
                    ExampleCardViewData(index: 2, title: "Design Three", color: .pink)
                ],
                designSystem: .light)
        }
        .background(Color.gray)
        .previewDisplayName("3 cards")
            
        ZStack {
            Carousel(
                cards: [
                    ExampleCardViewData(index: 0, title: "Design One", color: .red),
                    ExampleCardViewData(index: 1, title: "Design Two", color: .blue),
                    ExampleCardViewData(index: 2, title: "Design Three", color: .red),
                    ExampleCardViewData(index: 3, title: "Design Four", color: .blue),
                    ExampleCardViewData(index: 4, title: "Design Five", color: .pink)
                ],
                designSystem: .light)
        }
        .background(Color.gray)
        .previewDisplayName("5 cards")
    }
}
#endif

// Add corner radius extension for specific corners
#if os(iOS)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#endif
