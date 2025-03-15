import SwiftUI

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

/// A struct that holds design system values for consistent styling across components
/// It holds a hierarchy of design system properties ranging from common values such as text/accent color to checkbox text color with defaults an fallback values to ensure that init only requires few parameters.
public struct DesignSystemSetup {
    // MARK: - Colors
    
    /// Primary text color
    public let textColor: Color
    
    /// Dynamic text color (used when static text color is not specified)
    public let dynamicTextColor: Color
    
    /// Accent color used for interactive elements
    public let accentColor: Color
    
    /// Background color for cards and containers
    public let backgroundColor: Color
    
    /// Color for borders
    public let borderColor: Color
    
    /// Color for shadows
    public let shadowColor: Color
    
    /// Color for placeholders
    public let placeholderColor: Color
    
    // MARK: - Text Styling
    
    /// Whether to use glow effect for text
    public let useGlowEffect: Bool
    
    /// The color of the glow effect
    public let glowColor: Color
    
    /// The opacity of the glow effect
    public let glowOpacity: Double
    
    /// The radius of the glow effect
    public let glowRadius: CGFloat
    
    // MARK: - Spacing
    
    /// Standard spacing between elements
    public let standardSpacing: CGFloat
    
    /// Spacing between cards in a stack
    public let cardSpacing: CGFloat
    
    /// Spacing between checkbox items
    public let checkboxSpacing: CGFloat
    
    // MARK: - Sizes
    
    /// Standard card size
    public let cardSize: CGFloat
    
    /// Height of checkbox items
    public let checkboxItemHeight: CGFloat
    
    /// Border width for cards and containers
    public let borderWidth: CGFloat
    
    /// Shadow radius for cards
    public let shadowRadius: CGFloat
    
    /// Corner radius for cards
    public let cornerRadius: CGFloat
    
    // MARK: - Animation
    
    /// Duration for standard animations
    public let animationDuration: Double
    
    /// Rotation angle between cards in a stack
    public let cardRotation: CGFloat

    public var checkboxTextColor: Color
    public var checkboxColor: Color
    public let checkboxAnimationDuration: Double
    public let cardCornerRadius: CGFloat
    public var cardBorderColor: Color
    public let cardBorderWidth: CGFloat
    public let showCardShadow: Bool
    public let cardShadowColor: Color
    public let cardShadowRadius: CGFloat
    public let cardPlaceholderColor: Color

    public var checkboxStyle: CheckboxStyle
    public var showCheckboxBorder: Bool
    public let checkboxTextAlignment: CheckboxTextAlignment
    public let animateCheckboxOnAppear: Bool
    
    // MARK: - Initialization
    
    /// Creates a new DesignSystemSetup with default values
    ///   - checkboxItemHeight: Height of each checkbox item
    ///   - checkboxSpacing: Spacing between checkbox items
    public init(
        textColor: Color = .primary,
        dynamicTextColor: Color = .primary,
        accentColor: Color = .blue,
        backgroundColor: Color = .white,
        borderColor: Color = .gray.opacity(0.2),
        shadowColor: Color = .black.opacity(0.1),
        placeholderColor: Color = .gray.opacity(0.2),
        useGlowEffect: Bool = false,
        glowColor: Color = .white,
        glowOpacity: Double = 0.5,
        glowRadius: CGFloat = 10,
        standardSpacing: CGFloat = 20,
        cardSpacing: CGFloat = 12,
        checkboxSpacing: CGFloat = 8,
        cardSize: CGFloat = 60,
        checkboxItemHeight: CGFloat = 44,
        borderWidth: CGFloat = 1,
        shadowRadius: CGFloat = 4,
        cornerRadius: CGFloat = 8,
        animationDuration: Double = 0.5,
        cardRotation: CGFloat = 3,
        checkboxStyle: CheckboxStyle = .simple,
        showCheckboxBorder: Bool = false,
        checkboxTextAlignment: CheckboxTextAlignment = .left,
        animateCheckboxOnAppear: Bool = true
    ) {
        self.textColor = textColor
        self.dynamicTextColor = dynamicTextColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.placeholderColor = placeholderColor
        self.useGlowEffect = useGlowEffect
        self.glowColor = glowColor
        self.glowOpacity = glowOpacity
        self.glowRadius = glowRadius
        self.standardSpacing = standardSpacing
        self.cardSpacing = cardSpacing
        self.checkboxSpacing = checkboxSpacing
        self.cardSize = cardSize
        self.checkboxItemHeight = checkboxItemHeight
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
        self.cornerRadius = cornerRadius
        self.animationDuration = animationDuration
        self.cardRotation = cardRotation

        self.checkboxStyle = checkboxStyle
        self.showCheckboxBorder = showCheckboxBorder
        self.checkboxTextAlignment = checkboxTextAlignment
        self.animateCheckboxOnAppear = animateCheckboxOnAppear
        
        // Checkbox configuration
        checkboxTextColor = textColor
        checkboxColor = accentColor
        checkboxAnimationDuration = animationDuration
        
        // Image stack configuration
        cardCornerRadius = cornerRadius
        cardBorderColor = borderColor
        cardBorderWidth = borderWidth
        showCardShadow = true
        cardShadowColor = shadowColor
        cardShadowRadius = shadowRadius
        cardPlaceholderColor = placeholderColor
    }
    
    // MARK: - Presets
    
    /// Light theme preset
    public static let light = DesignSystemSetup(
        textColor: .black,
        dynamicTextColor: .black,
        accentColor: .blue,
        backgroundColor: .white,
        borderColor: .gray.opacity(0.2),
        shadowColor: .black.opacity(0.1),
        useGlowEffect: false,
        glowColor: .clear,
        glowOpacity: 0,
        glowRadius: 0
    )
    
    /// Dark theme preset
    public static let dark = DesignSystemSetup(
        textColor: .white,
        dynamicTextColor: .white,
        accentColor: .white,
        backgroundColor: .black,
        borderColor: .white.opacity(0.2),
        shadowColor: .white.opacity(0.3),
        useGlowEffect: false,
        glowColor: .clear,
        glowOpacity: 0,
        glowRadius: 0
    )
    
    /// Camera overlay preset
    public static let cameraOverlay = DesignSystemSetup(
        textColor: .white,
        dynamicTextColor: .white,
        accentColor: .white,
        backgroundColor: .clear,
        borderColor: .white.opacity(0.2),
        shadowColor: .black.opacity(0.3),
        placeholderColor: .white.opacity(0.2),
        useGlowEffect: true,
        glowColor: .white,
        glowOpacity: 0.5,
        glowRadius: 10,
        showCheckboxBorder: false,
        checkboxTextAlignment: .right
    )
} 
