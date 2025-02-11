// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import CoreGraphics

//import Capacitor
//import Combine

public enum CameraViewType: String {
    case Standard, AR, iOSDocument;
}

public struct InteractionProcess {
    var installURL: String = "https://thepia.net/vision-driven/blank"
    var runtimeURL: String = "https://thepia.net/vision-driven/blank"
    var query: String = ""
    var hash: String = ""
}

open class VDViewModel: ObservableObject {
    // UI Layout State
    @Published public var zoomState: WebViewZoomState = .TwoThirds
    @Published public var showCameraButton = true
    @Published public var showCameraView = true
    @Published public var showViewfinderFrame = false
    @Published public var cameraView: CameraViewType = .Standard   // This is changed based on CameraFeatures

    @Published public var showTopBar = true
    @Published public var title = "" // Title in the top bar
    
    @Published public var showAdvice = true

    // Would be optionally downloaded from the domain per App, possibly using imgset logic
    @Published var bgImageSet = "lined_room" // "orange_room". This will be "installed" per domain in the DB
    
    // Permissions to use camera/take picture
    @Published public var permissionGranted = false
    // TODO support monitoring permission, and start capture once granted
    @Published public var isCameraButtonDisabled = false
    var setupResult: SessionSetupResult = .success

    // Latest frame
    @Published public var frame: CGImage? // For streaming to view via CoreImage
    
    public var processStack = [InteractionProcess]()
    @Published public var processURLtoLoad: String?
    
    public init() {
        
    }

    public func setInterface(zoomState: WebViewZoomState?, cameraButton: Bool?, showCameraView: Bool?, showViewfinderFrame: Bool?) {
        DispatchQueue.main.sync {
            if let zoomState = zoomState {
                self.zoomState = zoomState
            }
            if let cameraButton = cameraButton {
                self.showCameraButton = cameraButton
            }
            if let showCameraView = showCameraView {
                self.showCameraView = showCameraView
            }
            if let showViewfinderFrame = showViewfinderFrame {
                self.showViewfinderFrame = showViewfinderFrame
            }
        }
        print("Interface state updated")
    }
    
    public func setTopBar(showTopBar: Bool?, title: String?) {
        DispatchQueue.main.sync {
            if let showTopBar = showTopBar {
                self.showTopBar = showTopBar
            }
            if let title = title {
                self.title = title
            }
        }
    }
    
    public func startProcess(_ process: InteractionProcess) {
        // save the query/hash of the existing app/page
        processStack.append(process)
        // apply the new process URL
        // if not install, do installURL first
        processURLtoLoad = process.installURL // or should this go in an iframe?
        // once installed go to runtimeURL
        // timeout for the install process, retry, flagging the URL
    }
    
    public func swipeZoomStateOn(_ height: Double, _ lower: Double, _ higher: Double) {
        if height < lower { // Swipe up
            if zoomState == .Hidden {
                zoomState = .TwoThirds
            } else if zoomState == .TwoThirds {
                zoomState = .FullScreen
            }
        } else if height > higher { // Swipe down
            if zoomState == .TwoThirds {
                zoomState = .Hidden
            } else if zoomState == .Hidden {
                zoomState = .TwoThirds
            }

        }
    }
}
