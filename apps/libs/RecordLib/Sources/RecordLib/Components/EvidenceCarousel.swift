import SwiftUI
import os

/*
/// A view that shows an interactive carousel of images, documents and video clips
public struct EvidenceCarousel: View {
    @ObservedObject var viewModel: RecordedThingViewModel
    
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.evidence-carousel")
    
    // State for managing the carousel
    @State private var offset: CGFloat = 0
    @State private var dragging = false
    
    // Constants for the carousel
    private let spacing: CGFloat = 20
    private let edgeFadeOpacity: CGFloat = 0.2
    private let centerScale: CGFloat = 1.0
    private let sideScale: CGFloat = 0.9
    private let dragThreshold: CGFloat = 50
    
    // MARK: - Initialization
    
    public init(viewModel: RecordedThingViewModel) {
        self.viewModel = viewModel
        logger.trace("EvidenceCarousel initialized")
    }
    
    // MARK: - Helper Methods
    
    private func position(for piece: EvidencePiece, in geometry: GeometryProxy) -> CGFloat {
        guard let currentIndex = viewModel.pieces.firstIndex(of: viewModel.currentPiece ?? piece),
              let pieceIndex = viewModel.pieces.firstIndex(of: piece) else {
            return 0
        }
        
        let itemWidth = geometry.size.width * 0.8 + spacing
        let basePosition = geometry.size.width/2 + CGFloat(pieceIndex - currentIndex) * itemWidth
        return basePosition + offset
    }
    
    private func opacity(for position: CGFloat, in geometry: GeometryProxy) -> Double {
        let center = geometry.size.width / 2
        let distance = abs(position - center)
        let maxDistance = geometry.size.width / 2
        
        if distance >= maxDistance {
            return edgeFadeOpacity
        } else {
            return 1.0 - (distance / maxDistance) * (1.0 - edgeFadeOpacity)
        }
    }
    
    private func scale(for position: CGFloat, in geometry: GeometryProxy) -> CGFloat {
        let center = geometry.size.width / 2
        let distance = abs(position - center)
        let maxDistance = geometry.size.width / 2
        
        if distance >= maxDistance {
            return sideScale
        } else {
            return centerScale - (distance / maxDistance) * (centerScale - sideScale)
        }
    }
    
    // MARK: - Gesture Handlers
    
    private func onDragChanged(_ value: DragGesture.Value) {
        offset = value.translation.width
        dragging = true
    }
    
    private func onDragEnded(_ value: DragGesture.Value) {
        dragging = false
        let predictedEndOffset = value.predictedEndTranslation.width
        let shouldAdvance = abs(predictedEndOffset) > dragThreshold
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if shouldAdvance {
                if predictedEndOffset > 0 {
                    viewModel.moveToPreviousPiece()
                } else {
                    viewModel.moveToNextPiece()
                }
            }
            offset = 0
        }
    }
    
    // MARK: - View Body
    
    public var body: some View {
        GeometryReader { geometry in
            let topTwoThirds = geometry.size.height * 0.67
            
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // Evidence carousel
                ZStack {
                    ForEach(viewModel.pieces) { piece in
                        let frameSize = CGSize(width: geometry.size.width * 0.8, height: geometry.size.height)
                        EvidenceView(piece: piece, frameSize: frameSize)
                            .zIndex(piece == viewModel.currentPiece ? 1 : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentPiece)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragging)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.setCurrentPiece(piece)
                                }
                            }
                    }
                }
                .frame(height: topTwoThirds)
                .gesture(
                    !viewModel.focusMode ?
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            dragging = true
                            onDragChanged(value)
                        }
                        .onEnded { value in
                            dragging = false
                            onDragEnded(value)
                        } : nil
                )
                
                // Page indicators
                if viewModel.pieces.count > 1 && !viewModel.focusMode {
                    HStack(spacing: 8) {
                        SwiftUI.ForEach(viewModel.pieces) { piece in
                            Circle()
                                .fill(piece == viewModel.currentPiece ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, topTwoThirds + 20)
                }
            }
        }
        .onAppear {
           logger.debug("EvidenceCarousel appeared with \(viewModel.pieces.count) pieces")
        }
    }
    
    @ViewBuilder
    private func evidenceView(for piece: EvidencePiece, in geometry: GeometryProxy) -> some View {
    }
}

/// A view that displays a single piece of evidence (image or video) in the carousel
private struct EvidenceView: View {
    let piece: EvidencePiece
    let frameSize: CGSize
    
    init(piece: EvidencePiece, frameSize: CGSize) {
        self.piece = piece
        self.frameSize = frameSize
    }
    
    var body: some View {
        switch piece.type {
        case .system(let name):
            Image(systemName: name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: frameSize.width, height: frameSize.height)
        case .custom(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: frameSize.width, height: frameSize.height)
        case .video:
            ZStack {
                Color.black
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                    Text("Tap to Play")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            .frame(width: frameSize.width, height: frameSize.height)
        }
    }
}

#if DEBUG
struct EvidenceCarousel_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default preview with multiple pieces
            VStack {
                Text("Default Evidence Carousel")
                    .font(.headline)
                
                EvidenceCarousel(viewModel: MockedRecordedThingViewModel.createDefault())
                    .frame(height: 300)
            }
            .previewDisplayName("Default")
            
            // Preview with video evidence
            VStack {
                Text("With Video Evidence")
                    .font(.headline)
                
                EvidenceCarousel(viewModel: MockedRecordedThingViewModel.create(
                    pieces: [
                        EvidencePiece(type: .system("photo"), metadata: ["type": "photo"]),
                        EvidencePiece(type: .video(URL(string: "video.mp4")!), metadata: ["type": "video"]),
                        EvidencePiece(type: .system("doc.text.image"), metadata: ["type": "document"])
                    ]
                ))
                .frame(height: 300)
            }
            .previewDisplayName("With Video")
            
            // Preview with single piece
            VStack {
                Text("Single Evidence Piece")
                    .font(.headline)
                
                EvidenceCarousel(viewModel: MockedRecordedThingViewModel.create(
                    pieces: [
                        EvidencePiece(type: .system("photo.fill"), metadata: ["type": "photo"])
                    ]
                ))
                .frame(height: 300)
            }
            .previewDisplayName("Single Piece")
            
            // Preview with no evidence
            VStack {
                Text("No Evidence")
                    .font(.headline)
                
                EvidenceCarousel(viewModel: MockedRecordedThingViewModel.create(pieces: []))
                    .frame(height: 300)
            }
            .previewDisplayName("Empty")
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .previewLayout(.sizeThatFits)
    }
}

// Sample pieces for previews and testing
public let samplePieces: [EvidencePiece] = [
    EvidencePiece.system("photo"),
    EvidencePiece.custom(Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.module)),
    EvidencePiece.video(URL(string: "video.mp4")!),
    EvidencePiece.system("doc.text.image"),
    EvidencePiece.system("photo.fill")
] 
#endif 
*/
