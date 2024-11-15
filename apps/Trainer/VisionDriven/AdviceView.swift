//
//  AdviceView.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 08.07.23.
//

import SwiftUI
import AVFoundation

public struct Advice {
    public var iconName: String? = nil
    public let text: String
    public var action: (() async -> Void)? = nil
}

public struct AdviceView: View {
    @EnvironmentObject var model: VDViewModel
 
    let advice: Advice
    
    public init(advice: Advice) {
        self.advice = advice
    }
    
    public var body: some View {
        if model.showAdvice {
            VStack {
                HStack {
                    if advice.iconName != nil {
                        if let action = advice.action {
                            Button(action: {
                                Task.init {
                                    await action()
                                }
                            }) {
                                Image(systemName: advice.iconName!)
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Image(systemName: advice.iconName!)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                    }
                    Text(advice.text)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding()
                }
            }
                .padding(10)
                .background(Color(white: 0, opacity: 0.125))
                // Future: .glassBackgroundEffect() (https://developer.apple.com/documentation/swiftui/view/glassbackgroundeffect(displaymode:))
                .mask(RoundedRectangle(cornerSize: CGSize(width: 16, height: 16)))
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                .frame(maxWidth: .infinity)
        }
    }
}

struct AdviceView_Previews: PreviewProvider {
    static var previews: some View {
        @State var permits: Int = 0
        @State var settings: Int = 0

        AdviceView(advice: Advice(text: "Capture must be allowed in settings")).environmentObject(VDViewModel()).previewDisplayName("Text Only")

        AdviceView(advice: Advice(iconName: "doc.viewfinder", text: "Capture must be allowed in settings" )).environmentObject(VDViewModel()).previewDisplayName("Text + Icon")
  
        VStack {
            AdviceView(advice: Advice(
                iconName: "camera.fill",
                text: "Capture must be allowed in settings",
                action: {
                    permits += 1
                    print("permit action")
                }
            ))
            Spacer()
            Text("\(permits) permits")
            Text("\(settings) recordings")
        }
        .environmentObject(VDViewModel()).previewDisplayName("Permits: Text + Icon + Action")
//        AdviceView().environmentObject(ViewModel(.notDetermined, MockStored())).previewDisplayName("Undetermined")
//        AdviceView().environmentObject(ViewModel(.authorized, MockStored())).previewDisplayName("Allowed")
    }
}
