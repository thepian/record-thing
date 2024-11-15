//
//  VisionDrivenApp.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 21.10.2023.
//s

import SwiftUI

//@main
struct VisionDrivenApp: App {
    @StateObject var model = VDViewModel()
    
    var body: some Scene {
        WindowGroup {
            VisionContentView().environmentObject(model)
        }
    }
}
