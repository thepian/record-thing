import SwiftUI
import os

/// A model representing an item in the checkbox carousel
public struct CheckboxItem: Identifiable, Equatable {
    public var id = UUID()
    public var text: String
    public var isChecked: Bool
    
    public init(text: String, isChecked: Bool = false) {
        self.text = text
        self.isChecked = isChecked
    }
    
    public static func == (lhs: CheckboxItem, rhs: CheckboxItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Orientation options for the checkbox carousel
public enum CarouselOrientation {
    case vertical
    case horizontal
}

/// A carousel of checkbox items with animations
public struct CheckboxCarouselView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.checkbox-carousel")
    
    // State
    @State private var visibleItems: [CheckboxItem] = []
    @State private var isAnimating = false
    @State private var bottomBorderOpacity: Double = 1.0
    @State private var newItemAppeared: Bool = false
     
    // ViewModel
    @ObservedObject private var viewModel: RecordedThingViewModel
    let designSystem: DesignSystemSetup
       
    // MARK: - Initialization
    
    /// Creates a new CheckboxCarouselView
    /// - Parameters:
    ///   - viewModel: The view model that manages the state and business logic
    public init(
        viewModel: RecordedThingViewModel
    ) {
        self.viewModel = viewModel
        self.designSystem = viewModel.designSystem

        logger.debug("CheckboxCarouselView initialized with view model")
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if viewModel.checkboxOrientation == .vertical {
                verticalCarousel
            } else {
                horizontalCarousel
            }
        }
        .onAppear {
            // Initialize visible items
            updateVisibleItems()
            
            // Start animation cycle if there are more items than visible slots
            if viewModel.checkboxItems.count > viewModel.maxCheckboxItems {
                startAnimationCycle()
            }
            
            // Trigger checkmark animations after a delay to allow slide-in to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + designSystem.checkboxAnimationDuration + 0.1) {
                newItemAppeared = true
            }
        }
        .onChange(of: viewModel.checkboxItems) { _ in
            logger.debug("Items changed, updating visible items")
            updateVisibleItems()
        }
    }
    
    // MARK: - UI Components
    
    /// Vertical carousel layout
    private var verticalCarousel: some View {
        VStack(spacing: designSystem.checkboxSpacing) {
            ForEach(visibleItems) { item in
                CheckboxItemView(
                    item: item,
                    designSystem: designSystem,
                    height: designSystem.checkboxItemHeight,
                    textAlignment: designSystem.checkboxTextAlignment,
                    animateOnAppear: newItemAppeared
                ) { toggledItem in
                    toggleItem(toggledItem)
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .id("\(item.id)-\(item.isChecked)") // Force view refresh when checked state changes
            }
            
            // Bottom border that fades in/out during animations
            if designSystem.showCheckboxBorder {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(designSystem.textColor)
                    .opacity(bottomBorderOpacity)
                    .padding(.top, 4)
            }
        }
    }
    
    /// Horizontal carousel layout
    private var horizontalCarousel: some View {
        HStack(spacing: designSystem.checkboxSpacing) {
            ForEach(visibleItems) { item in
                CheckboxItemView(
                    item: item,
                    designSystem: designSystem,
                    height: designSystem.checkboxItemHeight,
                    textAlignment: designSystem.checkboxTextAlignment,
                    animateOnAppear: newItemAppeared
                ) { toggledItem in
                    toggleItem(toggledItem)
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
                .id("\(item.id)-\(item.isChecked)") // Force view refresh when checked state changes
            }
            
            // Right border that fades in/out during animations (only visible in horizontal mode)
            if viewModel.checkboxOrientation == .horizontal && designSystem.showCheckboxBorder {
                Rectangle()
                    .frame(width: 1, height: 40)
                    .foregroundColor(designSystem.textColor)
                    .opacity(bottomBorderOpacity)
                    .padding(.leading, 4)
            }
        }
    }
        
    // MARK: - Methods
    
    /// Updates the list of visible items
    private func updateVisibleItems() {
        // Show only the first maxVisibleItems
        visibleItems = Array(viewModel.checkboxItems.prefix(viewModel.maxCheckboxItems))
        logger.debug("Updated visible items: \(visibleItems.map { $0.text }.joined(separator: ", "))")
    }
    
    /// Starts the animation cycle
    private func startAnimationCycle() {
        guard !isAnimating && viewModel.checkboxItems.count > viewModel.maxCheckboxItems else { return }
        
        isAnimating = true
        logger.debug("Starting animation cycle with orientation: \(viewModel.checkboxOrientation == .vertical ? "vertical" : "horizontal")")
        
        // Schedule the next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.animateNextItem()
        }
    }
    
    /// Animates the next item into view
    private func animateNextItem() {
        guard viewModel.checkboxItems.count > viewModel.maxCheckboxItems else {
            isAnimating = false
            return
        }
        
        // Reset the new item appeared flag
        newItemAppeared = false
        
        // Fade out the border
        withAnimation(.easeInOut(duration: designSystem.checkboxAnimationDuration / 2)) {
            bottomBorderOpacity = 0.0
        }
        
        // After a short delay, animate in the new item and remove the top/first one
        DispatchQueue.main.asyncAfter(deadline: .now() + designSystem.checkboxAnimationDuration / 2) {
            withAnimation(.easeInOut(duration: designSystem.checkboxAnimationDuration)) {
                // Find the next item to add
                if let lastVisibleItem = self.visibleItems.last,
                   let lastIndex = self.viewModel.checkboxItems.firstIndex(where: { $0.id == lastVisibleItem.id }) {
                    
                    // Remove the first item
                    if !self.visibleItems.isEmpty {
                        self.visibleItems.removeFirst()
                    }
                    
                    // Add the next item or cycle back to the beginning
                    let nextIndex = (lastIndex + 1) % self.viewModel.checkboxItems.count
                    self.visibleItems.append(self.viewModel.checkboxItems[nextIndex])
                    
                    self.logger.debug("Animated to next item: \(self.viewModel.checkboxItems[nextIndex].text), index: \(nextIndex)")
                } else if !self.viewModel.checkboxItems.isEmpty {
                    // Fallback if we can't find the last visible item in the items array
                    self.visibleItems = [self.viewModel.checkboxItems[0]]
                    self.logger.debug("Reset to first item: \(self.viewModel.checkboxItems[0].text)")
                }
                
                // Fade in the border
                self.bottomBorderOpacity = 1.0
            }
            
            // Trigger checkmark animations after a delay to allow slide-in to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + designSystem.checkboxAnimationDuration + 0.1) {
                self.newItemAppeared = true
            }
            
            // Schedule the next animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.animateNextItem()
            }
        }
    }
    
    /// Toggles the checked state of an item
    private func toggleItem(_ item: CheckboxItem) {
        // Find and update the item in both arrays
        if let index = viewModel.checkboxItems.firstIndex(where: { $0.id == item.id }) {
            viewModel.checkboxItems[index].isChecked.toggle()
            logger.debug("Toggled item: \(viewModel.checkboxItems[index].text), isChecked: \(viewModel.checkboxItems[index].isChecked)")
        }
        
        if let visibleIndex = visibleItems.firstIndex(where: { $0.id == item.id }) {
            visibleItems[visibleIndex].isChecked.toggle()
        }
    }
}

/// A single checkbox item view
struct CheckboxItemView: View {
    // MARK: - Properties
    
    @State var item: CheckboxItem
    let designSystem: DesignSystemSetup
    let height: CGFloat
    let textAlignment: CheckboxTextAlignment
    let animateOnAppear: Bool
    let onToggle: (CheckboxItem) -> Void
    
    // Animation state for flourish effect
    @State private var animateCheckmark: Bool = false
    
    // Computed shadow color (inverse of text color)
    private var shadowColor: Color {
        // Determine if text color is light or dark
        let brightness = designSystem.textColor.brightness
        // Return black for light colors, white for dark colors
        return brightness > 0.5 ? .black : .white
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            if textAlignment == .right {
                Spacer()
                
                // Text on left, checkmark on right
                Text(item.text)
                    .foregroundColor(designSystem.textColor)
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .shadow(color: shadowColor.opacity(0.8), radius: 2, x: 0, y: 0)
                    .lineLimit(1)
                
                // Checkbox or checkmark on right
                checkboxView
            } else {
                // Checkbox or checkmark on left (default)
                checkboxView
                
                // Text on right
                Text(item.text)
                    .foregroundColor(designSystem.textColor)
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .shadow(color: shadowColor.opacity(0.8), radius: 2, x: 0, y: 0)
                    .lineLimit(1)
                
                Spacer()
            }
        }
        .frame(height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateCheckmark = false
            }
            
            // Small delay before toggling to allow animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onToggle(item)
                
                // Only animate if becoming checked
                if !item.isChecked {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        animateCheckmark = true
                    }
                }
            }
        }
        .onAppear {
            // Only animate checkmark if item is checked AND we should animate on appear
            if item.isChecked && animateOnAppear {
                // Delay the animation to ensure the slide-in has completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        animateCheckmark = true
                    }
                }
            } else {
                // Set the state without animation
                animateCheckmark = item.isChecked
            }
        }
        .onChange(of: animateOnAppear) { newValue in
            // When animateOnAppear changes to true, trigger the checkmark animation
            if newValue && item.isChecked && !animateCheckmark {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateCheckmark = true
                }
            }
        }
        .onChange(of: item.isChecked) { isChecked in
            if isChecked {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animateCheckmark = true
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Checkbox or checkmark view
    private var checkboxView: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateCheckmark = false
            }
            
            // Small delay before toggling to allow animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onToggle(item)
                
                // Only animate if becoming checked
                if !item.isChecked {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        animateCheckmark = true
                    }
                }
            }
        }) {
            if designSystem.checkboxStyle == .boxed {
                // Traditional boxed checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(designSystem.checkboxColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if item.isChecked {
                        FlourishingCheckmark(color: designSystem.checkboxColor, animate: $animateCheckmark)
                            .frame(width: 20, height: 20)
                    }
                }
            } else {
                // Simple flourishing checkmark style (no box)
                if item.isChecked {
                    FlourishingCheckmark(color: designSystem.checkboxColor, animate: $animateCheckmark)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A clean, sharp checkmark with a pen-like drawing animation
struct FlourishingCheckmark: View {
    let color: Color
    @Binding var animate: Bool
    
    var body: some View {
        ZStack {
            // Main checkmark stroke - clean and sharp
            Path { path in
                // Start from bottom left
                path.move(to: CGPoint(x: 3, y: 12))
                
                // Straight line to middle point
                path.addLine(to: CGPoint(x: 9, y: 16))
                
                // Straight line to top right
                path.addLine(to: CGPoint(x: 21, y: 4))
            }
            .trim(from: 0, to: animate ? 1.0 : 0.0)
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .animation(Animation.easeInOut(duration: 0.6), value: animate)
        }
        .frame(width: 24, height: 24)
    }
}

// Add extension to determine color brightness
extension Color {
    // Returns a value between 0 (black) and 1 (white)
    var brightness: CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Convert to UIColor to access RGB components
        #if os(iOS) || os(tvOS)
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif os(macOS)
        NSColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        
        // Calculate perceived brightness using the formula:
        // (0.299*R + 0.587*G + 0.114*B)
        // This gives more weight to green as human eyes are more sensitive to it
        return (0.299 * red + 0.587 * green + 0.114 * blue)
    }
}

// MARK: - Preview

struct CheckboxCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var viewModel = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take a photo of the product"),
                CheckboxItem(text: "Scan the barcode"),
                CheckboxItem(text: "Capture the receipt"),
                CheckboxItem(text: "Add product details"),
                CheckboxItem(text: "Save to your collection")
            ],
            cardImages: [
            
            ]
        )
        @StateObject var viewModel2 = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "Take a photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Add details"),
                CheckboxItem(text: "Save item")
            ],
            cardImages: [
                
            ],
            checkboxOrientation: .vertical,
            designSystem: DesignSystemSetup(
                checkboxStyle: .simple,
                showCheckboxBorder: false,
                checkboxTextAlignment: .right
            )
        )
        @StateObject var viewModel3 = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "First simple item", isChecked: true),
                CheckboxItem(text: "Second simple item")
            ], cardImages: [
            
            ],
            checkboxOrientation: .vertical,
            designSystem: DesignSystemSetup(checkboxStyle: .simple)
        )
        
        @StateObject var viewModel4 = RecordedThingViewModel(
            checkboxItems: [
                CheckboxItem(text: "First custom item"),
                CheckboxItem(text: "Second custom item", isChecked: true),
                CheckboxItem(text: "Third custom item")
            ],
            cardImages: [
                
            ],
            checkboxOrientation: .horizontal,
            designSystem: DesignSystemSetup(
                textColor: .yellow,
                accentColor: .orange,
                checkboxSpacing: 12,
                checkboxItemHeight: 50,
                animationDuration: 0.7,
                checkboxStyle: .simple,
                showCheckboxBorder: false,
                checkboxTextAlignment: .right
            )
        )
        

//        Group {
            // Dark background for better visibility
            ZStack {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 40) {
                    // Vertical carousel (default)
                    VStack {
                        Text("Vertical Carousel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        CheckboxCarouselView(
                            viewModel: viewModel
                        )
                        .frame(width: 300)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Horizontal carousel with right-aligned text
                    VStack {
                        Text("Right-Aligned Checkmarks")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        CheckboxCarouselView(
                            viewModel: viewModel2
                        )
                        .frame(width: 300)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Simple checkmark style
                    VStack {
                        Text("Simple Checkmark Style")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                        
                        CheckboxCarouselView(
                            viewModel: viewModel3
                        )
                        .frame(width: 300)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
//                .padding()
//            }
            .previewDisplayName("Carousel Variations")
            
            // Custom theme with horizontal orientation and simple checkmarks
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                CheckboxCarouselView(
                    viewModel: viewModel4
                )
                .frame(width: 300)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
            .previewDisplayName("Right-Aligned (No Border)")
        }
    }
} 
