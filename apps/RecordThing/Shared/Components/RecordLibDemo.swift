//
//  RecordLibDemo.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 06.03.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI
import RecordLib

// MARK: - Preview
struct RecordLibDemo_Previews: PreviewProvider {
    static var previews: some View {
        /*
        ZStack {
            Image("thepia_a_high-end_electric_mountain_bike_1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped() // This prevents the image from overflowing
        }
        .previewDisplayName("Asset")
         */
        
        ZStack {
            Color.gray
            // Background content (would be the camera in the real app)
            GeometryReader { geometry in
//                Image(packageResource: "thepia_a_high-end_electric_mountain_bike_1", ofType: "png")
                Image("thepia_a_high-end_electric_mountain_bike_1", bundle: Bundle.main)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // This prevents the image from overflowing
            }
            .ignoresSafeArea()
            
            // The floating toolbar
            StandardFloatingToolbar(
                onStackTapped: { print("Stack tapped") },
                onCameraTapped: { print("Camera tapped") },
                onAccountTapped: { print("Account tapped") }
            )
        }
        .previewDisplayName("Standard Toolbar")
        
        ZStack {
            // Background content using the mountain bike image
            GeometryReader { geometry in
                Image("thepia_a_high-end_electric_mountain_bike_2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // This prevents the image from overflowing
            }
            .ignoresSafeArea()
            
            // Custom floating toolbar
            FloatingToolbar {
                HStack {
                    Spacer()
                    Button(action: { print("Custom button 1") }) {
                        Image(systemName: "folder")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    CameraButton(action: { print("Camera tapped") })
                    Spacer()
                    Button(action: { print("Custom button 2") }) {
                        Image(systemName: "gear")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
        }
        .previewDisplayName("Custom Toolbar")
    }
}
