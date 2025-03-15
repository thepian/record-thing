import SwiftUI

/// A demonstration of the CheckboxImageCardView component with various configurations
public struct RecordedStackAndRequirementsViewDemo: View {
    // MARK: - Properties
    
    @State private var selectedLayout: LayoutOption = .horizontal
    @State private var selectedStyle: StyleOption = .standard
    @State private var selectedTheme: ThemeOption = .light
    
    // Sample checkbox items
    @State private var checkboxItems: [CheckboxItem] = [
        CheckboxItem(text: "Take a photo of the product"),
        CheckboxItem(text: "Scan the barcode"),
        CheckboxItem(text: "Capture the receipt"),
        CheckboxItem(text: "Add product details")
    ]
    
    // Sample card images
    @State private var cardImages: [ImageCardStack.CardImage] = [
        .system("camera.viewfinder"),
        .system("barcode.viewfinder"),
        .system("doc.text.image")
    ]
    
    // MARK: - Types
    
    enum LayoutOption: String, CaseIterable, Identifiable {
        case horizontal = "Horizontal"
        case vertical = "Vertical"
        
        var id: String { self.rawValue }
    }
    
    enum StyleOption: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case simple = "Simple"
        case custom = "Custom"
        
        var id: String { self.rawValue }
    }
    
    enum ThemeOption: String, CaseIterable, Identifiable {
        case light = "Light"
        case dark = "Dark"
        case colorful = "Colorful"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Body
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("CheckboxImageCardView Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Configuration options
                configurationSection
                
                // Divider
                Divider()
                    .padding(.horizontal)
                
                // Component preview
                componentPreview
                    .padding()
                    .background(backgroundForTheme)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                
                // Description
                descriptionSection
                    .padding(.horizontal)
                
                // Code example
                codeExampleSection
                    .padding()
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Configuration options section
    private var configurationSection: some View {
        VStack(spacing: 15) {
            // Layout picker
            Picker("Layout", selection: $selectedLayout) {
                ForEach(LayoutOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Style picker
            Picker("Style", selection: $selectedStyle) {
                ForEach(StyleOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Theme picker
            Picker("Theme", selection: $selectedTheme) {
                ForEach(ThemeOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
    }
    
    /// Component preview based on selected options
    private var componentPreview: some View {
        RecordedStackAndRequirementsView(
            checkboxItems: checkboxItems,
            cardImages: cardImages,
            direction: selectedLayout == .horizontal ? .horizontal : .vertical,
            spacing: 20,
            maxVisibleItems: 1,
            checkboxTextColor: textColorForTheme,
            checkboxColor: accentColorForTheme,
            checkboxStyle: checkboxStyleForSelection,
            showCheckboxBorder: selectedStyle != .simple,
            cardSize: 60,
            cardBorderColor: accentColorForTheme,
            onItemToggled: { item in
                // Update the item in our local array
                if let index = checkboxItems.firstIndex(where: { $0.id == item.id }) {
                    checkboxItems[index].isChecked = item.isChecked
                }
            }
        )
    }
    
    /// Description of the component
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About this Component")
                .font(.headline)
            
            Text("The CheckboxImageCardView combines a CheckboxCarouselView and an ImageCardStack in a single component. It's useful for displaying a list of tasks or options alongside related images.")
                .font(.body)
            
            Text("Use Cases:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("• Product onboarding flows")
                Text("• Task checklists with visual references")
                Text("• Multi-step processes with image examples")
                Text("• Feature tours with screenshots")
            }
            .font(.body)
        }
    }
    
    /// Code example for the component
    private var codeExampleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Example Code")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text("""
                CheckboxImageCardView(
                    checkboxItems: [
                        CheckboxItem(text: "Take a photo"),
                        CheckboxItem(text: "Scan barcode", isChecked: true),
                        CheckboxItem(text: "Add details")
                    ],
                    cardImages: [
                        .system("photo"),
                        .system("camera"),
                        .system("doc.text.image")
                    ],
                    direction: .\(selectedLayout == .horizontal ? "horizontal" : "vertical"),
                    checkboxStyle: .\(selectedStyle == .simple ? "simple" : "boxed")
                )
                """)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Background color based on selected theme
    private var backgroundForTheme: Color {
        switch selectedTheme {
        case .light:
            return Color.white
        case .dark:
            return Color.black
        case .colorful:
            return Color.blue.opacity(0.2)
        }
    }
    
    /// Text color based on selected theme
    private var textColorForTheme: Color {
        switch selectedTheme {
        case .light:
            return .black
        case .dark:
            return .white
        case .colorful:
            return .primary
        }
    }
    
    /// Accent color based on selected theme
    private var accentColorForTheme: Color {
        switch selectedTheme {
        case .light:
            return .blue
        case .dark:
            return .white
        case .colorful:
            return .orange
        }
    }
    
    /// Checkbox style based on selected style
    private var checkboxStyleForSelection: CheckboxStyle {
        switch selectedStyle {
        case .standard, .custom:
            return .boxed
        case .simple:
            return .simple
        }
    }
}

// MARK: - Preview

struct CheckboxImageCardViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        RecordedStackAndRequirementsViewDemo()
    }
}
