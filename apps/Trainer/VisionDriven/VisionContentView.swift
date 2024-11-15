//
//  ContentView.swift
//  VisionDriven
//
//  Created by Henrik Vendelbo on 21.10.2023.
//

import SwiftUI

struct VisionContentView: View {
    @EnvironmentObject var model: VDViewModel
    
    var body: some View {
        ZStack {
//            WebAppView(model: model)
            VStack {
                Spacer()
                AdviceView(advice: Advice(
                    iconName: "camera.fill",
                    text: "Capture must be allowed in settings",
                    action: {
                        print("permit action")
                    }
                ))
                .environmentObject(VDViewModel()).previewDisplayName("Permits: Text + Icon + Action")
            }
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")

            }
            .padding()
        }
    }
}

#Preview {
    VisionContentView().environmentObject(VDViewModel())
}
