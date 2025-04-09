import SwiftUI
import os

public struct CameraSubduedSwitcher: View {
    @ObservedObject public var captureService: CaptureService
    public let designSystem: DesignSystemSetup
    
    private let logger = Logger(subsystem: "com.record-thing", category: "CameraSubduedSwitcher")
    
    public init(captureService: CaptureService, designSystem: DesignSystemSetup) {
        self.captureService = captureService
        self.designSystem = designSystem
    }
    
    public var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                captureService.isSubdued.toggle()
                logger.debug("Camera subdued mode toggled: \(captureService.isSubdued)")
            }
        }) {
            Image(systemName: captureService.isSubdued ? "battery.25" : "battery.100")
                .foregroundColor(designSystem.accentColor)
                .padding(8)
                .background(
                    Circle()
                        .fill(designSystem.backgroundColor)
                        .shadow(radius: designSystem.shadowRadius)
                )
        }
        .help(captureService.isSubdued ? "Switch to high performance mode" : "Switch to power saving mode")
    }
}

#if DEBUG
struct CameraSubduedSwitcher_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CameraSubduedSwitcher(
                captureService: CaptureService(),
                designSystem: .light
            )
        }
        .padding()
        .background(Color.gray)
    }
}
#endif 