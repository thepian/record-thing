//
//  ReservedForCameraView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 08.07.23.
//

import SwiftUI
import AVFoundation
import os

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// TODO perhaps the request should be in WebLogic

public struct ReservedForCameraView: View {
    @Environment(\.cameraViewModel) var cameraViewModel: CameraViewModel?
    var statusCameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video)
    
    // Get screen dimensions in a cross-platform way
    #if os(macOS)
    private var screenWidth: CGFloat {
        NSScreen.main?.frame.width ?? 800
    }
    private var screenHeight: CGFloat {
        NSScreen.main?.frame.height ?? 600
    }
    #else
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    #endif
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui.camera-view")

    public init() {
        logger.debug("ReservedForCameraView initialized")
    }

    public var body: some View {
        if cameraViewModel?.showCamera ?? false {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 10)
                    .stroke(Color.yellow, lineWidth: cameraViewModel?.showViewfinderFrame ?? false ? 2 : 0)
                    .aspectRatio(contentMode: .fill)
                
                VStack {
                    HStack {
                        Image(systemName: cameraViewModel?.adviceIconName ?? "camera")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text(cameraViewModel?.adviceText ?? "Position the object in the frame")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(10)
                .background(Color(white: 0, opacity: 0.25))
                .mask(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                // Use cross-platform dimensions
                .frame(maxWidth: screenWidth, minHeight: screenWidth, idealHeight: screenWidth)
                .onAppear {
                    logger.debug("Camera view appeared, screen dimensions: \(screenWidth) x \(screenHeight)")
                }
            }
        } else {
            // Empty view when camera is not shown
            EmptyView()
                .onAppear {
                    logger.debug("Camera view not shown (showCamera is false)")
                }
        }
    }
}

#if DEBUG
struct ReservedForCameraView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                // Use a color instead of an image for better cross-platform preview
                Color.orange.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Before")
                    ReservedForCameraView()
                        .environment(\.cameraViewModel, CameraViewModel(status: .authorized, showViewfinderFrame: true))
                    Text("After")
                }
            }
            .previewDisplayName("With frame")

            ZStack {
                Color.orange.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Before")
                    ReservedForCameraView()
                        .environment(\.cameraViewModel, CameraViewModel(status: .authorized, showViewfinderFrame: false))
                    Text("After")
                }
            }
            .previewDisplayName("No frame")
        }
    }
}
#endif
