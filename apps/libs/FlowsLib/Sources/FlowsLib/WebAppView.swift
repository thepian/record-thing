//
//  WebAppView.swift
//  FlowsLib
//
//  Created by Henrik Vendelbo on 22.11.2025.
//

/*
 Onboarding is a sheet popup that appears as a prerequisite for a particular
 destination.
 
 This must be generalised to be a WebAppView that can act as a sheet, popover or widget/tile. The config sets the native expectation, and the web page calls activate with an updated config for running that would normally agree with the expectation.
 
 The onboarding state will have progress state so the WebViewApp can be shown as needed.
 
 Onboarding cases
 - Sign Up
 - Change plan
 - Camera/Microphone permissions
 - First time using
 */
import SwiftUI
import FlowsLib

public struct WebAppView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var state: WebAppState
  
  let config: WebAppConfig
  
  public init(config: WebAppConfig = WebAppConfig(startURL: URL(string: "https://app.thepia.net")), initialReadiness: WebAppReadiness = .loading) {
      self.config = config
      _state = StateObject(wrappedValue: WebAppState(
          initialPageHeight: config.initialPageHeight, 
          initialReadiness: initialReadiness,
          initialBackgroundMaterial: config.backgroundMaterial
      ))
  }
    
  @State private var keyboardHeight: CGFloat = 0

  public var body: some View {
    VStack(spacing: 0) {
      if state.pageHeight != .full {
          Spacer()
      }
      webView
        .frame(height: heightForState)
        .frame(maxWidth: .infinity, maxHeight: state.pageHeight == .full ? .infinity : nil)
    }
    .padding(.bottom, state.pageHeight == .full ? 0 : keyboardHeight)
    .ignoresSafeArea(edges: state.pageHeight == .full ? .all : .bottom)
    .opacity(opacityForState)
    .offset(y: offsetForState)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state.pageHeight)
    .animation(.easeIn(duration: 0.3), value: state.readiness)
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            withAnimation(.easeOut(duration: 0.25)) {
                self.keyboardHeight = keyboardFrame.height
            }
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
        withAnimation(.easeOut(duration: 0.25)) {
            self.keyboardHeight = 0
        }
    }
    .onChange(of: state.readiness) { newValue in
        if newValue == .completed {
            dismiss()
        }
    }
  }
    
  var heightForState: CGFloat? {
      switch state.pageHeight {
      case .pill: return 200
      case .sheet: return 580
      case .full: return nil
      }
  }
    
  var opacityForState: Double {
      if state.readiness != .ready { return 0 }
      return 1
  }
    
  var offsetForState: CGFloat {
      if state.pageHeight == .sheet && state.readiness != .ready { return 600 }
      return 0
  }
    
  var webView: some View {
      // Create a mutable copy of config to add the handler
      var viewConfig = config
      
      // Add the 'thepia' message handler
      viewConfig.messageHandlers["thepia"] = { message in
          if let dict = message as? [String: Any] {
              state.handleMessage(dict)
          }
      }
      
      let cornerRadius: CGFloat = state.pageHeight == .full ? 0 : 24
      let shape = UnevenRoundedRectangle(topLeadingRadius: cornerRadius, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: cornerRadius)
      
      return CapacitorView(config: viewConfig)
          .clipShape(shape)
          .background(
            Group {
                switch state.backgroundMaterial {
                case .clear:
                    shape.fill(.clear)
                case .thinMaterial:
                    shape.fill(.thinMaterial)
                case .ultraThinMaterial:
                    shape.fill(.ultraThinMaterial)
                case .regularMaterial:
                    shape.fill(.regularMaterial)
                case .thickMaterial:
                    shape.fill(.thickMaterial)
                }
            }
          )
  }

}

struct WebAppView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
        // Simulate a real loading flow
        WebAppView(config: WebAppConfig(startURL: URL(string: "https://app.thepia.net"))
            .messageHandler("thepia") { _ in }, // Mock handler
            initialReadiness: .loading
        )
            .presentationBackground(.clear)
            .modifier(PreviewBackground())
            .previewDisplayName("Loading State Demo")
            .onAppear {
                // Simulate web app sending 'ready' signal after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // We can't easily inject into the internal state here without exposing it,
                    // but in a real app the WebView would call the handler.
                    // For preview purposes, we might need a way to trigger it or just rely on .ready for static previews.
                }
            }
        
        WebAppView(initialReadiness: .ready)
            .presentationBackground(.clear)
            .modifier(PreviewBackground())
            .previewDisplayName("Ready State (Static)")
        
        WebAppView(config: WebAppConfig()
            .startURL(URL(string: "https://dev.thepia.net:5173/setup"))
            .initialPageHeight(.full),
            initialReadiness: .ready
        )
            .presentationBackground(.clear)
            .modifier(PreviewBackground())
            .previewDisplayName("dev.thepia.net setup")
    }
  }
}

private struct PreviewBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                // Using AsyncImage to avoid Bundle.module complexity in previews
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                    } else {
                        Color.gray.ignoresSafeArea()
                    }
                }
            }
    }
}
