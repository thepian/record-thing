//
//  CapacitorView.swift
//  Treasure
//
#if canImport(UIKit)

import SwiftUI
import WebKit


public struct CapacitorViewIOS: UIViewControllerRepresentable {
    
    private let makeViewController: () -> UIViewController
    
    public init(config: WebAppConfig = WebAppConfig(), makeViewController: @escaping () -> UIViewController = {
          return FlowsWebViewController()
      /* Capacitor tries to access share extension so sandbox is kicking in
        if ProcessInfo.isSwiftUIPreview {
          print("CapacitorView: Using FlowsWebViewController (Preview Mode)")
          return FlowsWebViewController()
        } else {
          print("CapacitorView: Using FlowsBridgeViewController (Standard Mode)")
          return FlowsBridgeViewController()
        }
       */
      }) {
        self.makeViewController = {
            let vc = makeViewController()
            if let bridgeVC = vc as? FlowsBridgeViewController {
                bridgeVC.config = config
            }
            if let webVC = vc as? FlowsWebViewController {
              webVC.config = config
            }
            return vc
        }
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<CapacitorViewIOS>) -> some UIViewController {
        let viewController = makeViewController()
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<CapacitorViewIOS>) {
        
    }
}

struct CapacitorViewIOS_Previews: PreviewProvider {
    static var previews: some View {
      CapacitorView(config: WebAppConfig(startURL: URL(string: "https://app.thepia.net")))
      .frame(height: 400)
      .background(.ultraThinMaterial)
      .previewDisplayName("Flows WKWebView Test")

      CapacitorView(config: WebAppConfig(startURL: URL(string: "https://dev.thepia.net:5173/setup")))
      .frame(height: 400)
      .background(.ultraThinMaterial)
      .previewDisplayName("dev.thepia.net setup")
    }
}


// Platform-specific typealias
public typealias CapacitorView = CapacitorViewIOS

#endif

#if canImport(AppKit)
// Platform-specific typealias
public typealias CapacitorView = CapacitorViewMac
#endif
