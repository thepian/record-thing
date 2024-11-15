//
//  CustomARView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 02.07.23.
//

import ARKit
import SwiftUI
import RealityKit

class CustomARView: ARView {
    @EnvironmentObject var model: ViewModel

    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This is the init that we will actually use
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
//        self.session.captureHighResolutionFrame()
    }
}
