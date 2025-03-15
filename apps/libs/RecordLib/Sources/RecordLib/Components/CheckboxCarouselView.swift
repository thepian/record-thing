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

/// Style options for the checkbox
public enum CheckboxStyle {
    case boxed      // Traditional checkbox with a box
    case simple     // Just a checkmark when checked, nothing when unchecked
}

/// Text alignment options for the checkbox items
public enum CheckboxTextAlignment {
    case left       // Checkmark on left, text on right (default)
    case right      // Text on left, checkmark on right
}

/// A carousel of checkbox items with animations
public struct CheckboxCarouselView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.checkbox-carousel")
    
    // State
    @State private var items: [CheckboxItem]
    @State private var visibleItems: [CheckboxItem] = []
    @State private var isAnimating = false
    @State private var bottomBorderOpacity: Double = 1.0
    @State private var newItemAppeared: Bool = false
    
    // Configuration
    private let maxVisibleItems: Int
    private let textColor: Color
    private let checkboxColor: Color
    private let animationDuration: Double
    private let itemHeight: CGFloat
    private let spacing: CGFloat
    private let onItemToggled: ((CheckboxItem) -> Void)?
    private let orientation: CarouselOrientation
    private let checkboxStyle: CheckboxStyle
    private let showBorder: Bool
    private let textAlignment: CheckboxTextAlignment
    
    // MARK: - Initialization
    
    /// Creates a new CheckboxCarouselView
    /// - Parameters:
    ///   - items: Array of checkbox items to display
    ///   - maxVisibleItems: Maximum number of items visible at once (default: 2)
    ///   - textColor: Color of the text (default: white)
    ///   - checkboxColor: Color of the checkbox (default: white)
    ///   - animationDuration: Duration of animations in seconds (default: 0.5)
    ///   - itemHeight: Height of each item (default: 44)
    ///   - spacing: Spacing between items (default: 8)
    ///   - orientation: Direction of the carousel (vertical or horizontal)
    ///   - checkboxStyle: Style of the checkbox (boxed or simple)
    ///   - showBorder: Whether to show the border line (default: true)
    ///   - textAlignment: Alignment of text and checkmark (default: .left)
    ///   - onItemToggled: Callback when an item is toggled
    public init(
        items: [CheckboxItem],
        maxVisibleItems: Int = 2,
        textColor: Color = .white,
        checkboxColor: Color = .white,
        animationDuration: Double = 2.5,
        itemHeight: CGFloat = 44,
        spacing: CGFloat = 8,
        orientation: CarouselOrientation = .vertical,
        checkboxStyle: CheckboxStyle = .boxed,
        showBorder: Bool = true,
        textAlignment: CheckboxTextAlignment = .left,
        onItemToggled: ((CheckboxItem) -> Void)? = nil
    ) {
        self._items = State(initialValue: items)
        self.maxVisibleItems = maxVisibleItems
        self.textColor = textColor
        self.checkboxColor = checkboxColor
        self.animationDuration = animationDuration
        self.itemHeight = itemHeight
        self.spacing = spacing
        self.orientation = orientation
        self.checkboxStyle = checkboxStyle
        self.showBorder = showBorder
        self.textAlignment = textAlignment
        self.onItemToggled = onItemToggled
        
        logger.debug("CheckboxCarouselView initialized with \(items.count) items, orientation: \(orientation == .vertical ? "vertical" : "horizontal"), textAlignment: \(textAlignment == .left ? "left" : "right")")
    }
    
    // MARK: - Body
    
    public var body: some View {
        Group {
            if orientation == .vertical {
                verticalCarousel
            } else {
                horizontalCarousel
            }
        }
        .onAppear {
            // Initialize visible items
            updateVisibleItems()
            
            // Start animation cycle if there are more items than visible slots
            if items.count > maxVisibleItems {
                startAnimationCycle()
            }
            
            // Trigger checkmark animations after a delay to allow slide-in to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
                newItemAppeared = true
            }
        }
        .onChange(of: items) { _ in
            logger.debug("Items changed, updating visible items")
            updateVisibleItems()
        }
    }
    
    // MARK: - UI Components
    
    /// Vertical carousel layout
    private var verticalCarousel: some View {
        VStack(spacing: spacing) {
            ForEach(visibleItems) { item in
                CheckboxItemView(
                    item: item,
                    textColor: textColor,
                    checkboxColor: checkboxColor,
                    height: itemHeight,
                    checkboxStyle: checkboxStyle,
                    textAlignment: textAlignment,
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
            if showBorder {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(textColor)
                    .opacity(bottomBorderOpacity)
                    .padding(.top, 4)
            }
        }
    }
    
    /// Horizontal carousel layout
    private var horizontalCarousel: some View {
        HStack(spacing: spacing) {
            ForEach(visibleItems) { item in
                CheckboxItemView(
                    item: item,
                    textColor: textColor,
                    checkboxColor: checkboxColor,
                    height: itemHeight,
                    checkboxStyle: checkboxStyle,
                    textAlignment: textAlignment,
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
            if orientation == .horizontal && showBorder {
                Rectangle()
                    .frame(width: 1, height: 40)
                    .foregroundColor(textColor)
                    .opacity(bottomBorderOpacity)
                    .padding(.leading, 4)
            }
        }
    }
        
    // MARK: - Methods
    
    /// Updates the list of visible items
    private func updateVisibleItems() {
        // Show only the first maxVisibleItems
        visibleItems = Array(items.prefix(maxVisibleItems))
        logger.debug("Updated visible items: \(visibleItems.map { $0.text }.joined(separator: ", "))")
    }
    
    /// Starts the animation cycle
    private func startAnimationCycle() {
        guard !isAnimating && items.count > maxVisibleItems else { return }
        
        isAnimating = true
        logger.debug("Starting animation cycle with orientation: \(orientation == .vertical ? "vertical" : "horizontal")")
        
        // Schedule the next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.animateNextItem()
        }
    }
    
    /// Animates the next item into view
    private func animateNextItem() {
        guard items.count > maxVisibleItems else {
            isAnimating = false
            return
        }
        
        // Reset the new item appeared flag
        newItemAppeared = false
        
        // Fade out the border
        withAnimation(.easeInOut(duration: animationDuration / 2)) {
            bottomBorderOpacity = 0.0
        }
        
        // After a short delay, animate in the new item and remove the top/first one
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 2) {
            withAnimation(.easeInOut(duration: animationDuration)) {
                // Find the next item to add
                if let lastVisibleItem = self.visibleItems.last,
                   let lastIndex = self.items.firstIndex(where: { $0.id == lastVisibleItem.id }) {
                    
                    // Remove the first item
                    if !self.visibleItems.isEmpty {
                        self.visibleItems.removeFirst()
                    }
                    
                    // Add the next item or cycle back to the beginning
                    let nextIndex = (lastIndex + 1) % self.items.count
                    self.visibleItems.append(self.items[nextIndex])
                    
                    self.logger.debug("Animated to next item: \(self.items[nextIndex].text), index: \(nextIndex)")
                } else if !self.items.isEmpty {
                    // Fallback if we can't find the last visible item in the items array
                    self.visibleItems = [self.items[0]]
                    self.logger.debug("Reset to first item: \(self.items[0].text)")
                }
                
                // Fade in the border
                self.bottomBorderOpacity = 1.0
            }
            
            // Trigger checkmark animations after a delay to allow slide-in to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
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
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isChecked.toggle()
            logger.debug("Toggled item: \(items[index].text), isChecked: \(items[index].isChecked)")
            
            // Call the callback if provided
            if let onItemToggled = onItemToggled {
                onItemToggled(items[index])
            }
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
    let textColor: Color
    let checkboxColor: Color
    let height: CGFloat
    let checkboxStyle: CheckboxStyle
    let textAlignment: CheckboxTextAlignment
    let animateOnAppear: Bool
    let onToggle: (CheckboxItem) -> Void
    
    // Animation state for flourish effect
    @State private var animateCheckmark: Bool = false
    
    // Computed shadow color (inverse of text color)
    private var shadowColor: Color {
        // Determine if text color is light or dark
        let brightness = textColor.brightness
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
                    .foregroundColor(textColor)
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
                    .foregroundColor(textColor)
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
            if checkboxStyle == .boxed {
                // Traditional boxed checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(checkboxColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if item.isChecked {
                        FlourishingCheckmark(color: checkboxColor, animate: $animateCheckmark)
                            .frame(width: 20, height: 20)
                    }
                }
            } else {
                // Simple flourishing checkmark style (no box)
                if item.isChecked {
                    FlourishingCheckmark(color: checkboxColor, animate: $animateCheckmark)
                        .frame(width: 24, height: 24)
                } else {
                    // Empty space to maintain layout
//                    Color.clear
//                        .frame(width: 24, height: 24)
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
        Group {
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
                            items: [
                                CheckboxItem(text: "Take a photo of the product"),
                                CheckboxItem(text: "Scan the barcode"),
                                CheckboxItem(text: "Capture the receipt"),
                                CheckboxItem(text: "Add product details"),
                                CheckboxItem(text: "Save to your collection")
                            ],
                            onItemToggled: { item in
                                print("Item toggled: \(item.text), isChecked: \(item.isChecked)")
                            }
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
                            items: [
                                CheckboxItem(text: "Take a photo"),
                                CheckboxItem(text: "Scan barcode", isChecked: true),
                                CheckboxItem(text: "Add details"),
                                CheckboxItem(text: "Save item")
                            ],
                            maxVisibleItems: 1,
                            orientation: .horizontal,
                            checkboxStyle: .simple,
                            showBorder: false,
                            textAlignment: .right,
                            onItemToggled: { item in
                                print("Item toggled: \(item.text), isChecked: \(item.isChecked)")
                            }
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
                            items: [
                                CheckboxItem(text: "First simple item", isChecked: true),
                                CheckboxItem(text: "Second simple item")
                            ],
                            checkboxStyle: .simple,
                            onItemToggled: { item in
                                print("Item toggled: \(item.text), isChecked: \(item.isChecked)")
                            }
                        )
                        .frame(width: 300)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
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
                    items: [
                        CheckboxItem(text: "First custom item"),
                        CheckboxItem(text: "Second custom item", isChecked: true),
                        CheckboxItem(text: "Third custom item")
                    ],
                    maxVisibleItems: 1,
                    textColor: .yellow,
                    checkboxColor: .orange,
                    animationDuration: 0.7,
                    itemHeight: 50,
                    spacing: 12,
                    orientation: .horizontal,
                    checkboxStyle: .simple,
                    showBorder: false,
                    textAlignment: .right
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
