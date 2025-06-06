/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button style that squishes its content and optionally slightly fades it out when pressed
*/

import SwiftUI

public struct SquishableButtonStyle: ButtonStyle {
    var fadeOnPress: Bool
    
    public init(fadeOnPress: Bool = true) {
        self.fadeOnPress = fadeOnPress
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && fadeOnPress ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

extension ButtonStyle where Self == SquishableButtonStyle {
    public static var squishable: SquishableButtonStyle {
        SquishableButtonStyle()
    }
    
    public static func squishable(fadeOnPress: Bool = true) -> SquishableButtonStyle {
        SquishableButtonStyle(fadeOnPress: fadeOnPress)
    }
}
