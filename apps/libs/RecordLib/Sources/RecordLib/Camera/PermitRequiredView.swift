//
//  PermitRequiredView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 16.07.23.
//

import SwiftUI

public struct PermitRequiredView: View {
    @Environment(\.cameraViewModel) var cameraViewModel: CameraViewModel?
    @State var isLongPressing = false
    
    let iconName: String?
    
    public var permitAlert: () async -> Void
    public var showSettings: () async -> Void
    
    /// Public initializer for PermitRequiredView
    /// - Parameters:
    ///   - iconName: Optional system icon name to display
    ///   - text: The text message to display to the user
    ///   - permitAlert: Async closure to execute when requesting camera permission
    ///   - showSettings: Async closure to execute when opening settings
    public init(
        iconName: String? = nil,
        permitAlert: @escaping () async -> Void,
        showSettings: @escaping () async -> Void
    ) {
        self.iconName = iconName
        self.permitAlert = permitAlert
        self.showSettings = showSettings
    }
 
    public var body: some View {
        VStack {
            Spacer()
            
            VStack {
                if cameraViewModel?.onboardingState == .PermitVideoCapture {
                    HStack {
                        if iconName != nil {
                            Image(systemName: iconName!)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        Text(LocalizedStringKey("security.camera_notDetermined"))
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                    }
                    // TODO Pulse the button
                    Button(action: {
                        // TODO open the alert automatically if button isn't pressed after 30 seconds
                        Task {
                            await permitAlert()
                        }
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 4)
                                    .frame(width: 60, height: 60)
                            )
                            .padding()
                        
                    }
                    .buttonStyle(.plain)
                } else if cameraViewModel?.onboardingState == .CaptureInAppSettings {
                    HStack {
                        if iconName != nil {
                            Image(systemName: iconName!)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        Text(LocalizedStringKey("security.camera_denied"))
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                    }
                    Button(action: {
                        Task {
                            await showSettings()
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 4)
                                    .frame(width: 60, height: 60)
                            )
                            .padding()
                        
                    }
                    .buttonStyle(.plain)
                }

            }
                .padding()
                .background(Color(white: 0, opacity: 0.125))
                .mask(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
        }
    }
}

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

#if DEBUG
struct PermitRequiredView_Previews: PreviewProvider {
    
    static var previews: some View {
        let deniedModel = CameraViewModel(status: .denied)
        let indeterminateModel = CameraViewModel(status: .notDetermined)
        let restrictedModel = CameraViewModel(status: .restricted)
        @State var permits: Int = 0
        @State var settings: Int = 0

        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color.red, Color.blue]), center: .topLeading, startRadius: 25, endRadius: screenHeight)
            VStack {
                Spacer()
                HStack {
                    PermitRequiredView(
                        permitAlert: {
                            permits += 1
                        },
                        showSettings: {
                            settings += 1
                        })
                    .environment(\.cameraViewModel, deniedModel)
                }
                Spacer()
                Text("\(permits) permits")
                Text("\(settings) recordings")

            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .previewDisplayName("Denied")

        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color.red, Color.blue]), center: .topLeading, startRadius: 25, endRadius: screenHeight)
            VStack {
                Spacer()
                HStack {
                    PermitRequiredView(
                        permitAlert: {
                            permits += 1
                        },
                        showSettings: {
                            settings += 1
                        })
                    .environment(\.cameraViewModel, indeterminateModel)
                }
                Spacer()
                Text("\(permits) permits")
                Text("\(settings) recordings")

            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .previewDisplayName("Indeterminate")
    }
}
#endif
