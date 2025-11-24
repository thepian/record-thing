//
//  CapacitorViewMac.swift
//  FlowsLib
//
//  Created for macOS SwiftUI support
//

#if canImport(AppKit)
import SwiftUI
import AppKit

public struct CapacitorViewMac: NSViewControllerRepresentable {
    
    private let makeViewController: () -> NSViewController
    
    public init(config: WebAppConfig = WebAppConfig(), makeViewController: @escaping () -> NSViewController = { FlowsBridgeViewControllerMac() }) {
        self.makeViewController = {
            let vc = makeViewController()
            if let bridgeVC = vc as? FlowsBridgeViewControllerMac {
                bridgeVC.config = config
            }
            return vc
        }
    }
    
    public func makeNSViewController(context: NSViewControllerRepresentableContext<CapacitorViewMac>) -> NSViewController {
        return makeViewController()
    }
    
    public func updateNSViewController(_ nsViewController: NSViewController, context: NSViewControllerRepresentableContext<CapacitorViewMac>) {
        // Update if needed
    }
}

struct CapacitorViewMac_Previews: PreviewProvider {
    static var previews: some View {
        CapacitorViewMac()
    }
}

#endif
