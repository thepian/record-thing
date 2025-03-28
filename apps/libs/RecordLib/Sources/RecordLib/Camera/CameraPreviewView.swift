import SwiftUI
import os
import AVFoundation

/// A camera preview view with optional circular mask and object highlighting capabilities
public struct CameraPreviewView: View {
    // MARK: - Properties
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.record-thing", category: "ui")
    
    // State
    @State private var maskPosition: CGPoint = .zero
    @State private var highlightedObjects: [DetectedObject] = []
    @State private var animationProgress: Double = 0
    
    // Configuration
    private let showMask: Bool
    private let maskRadius: CGFloat
    private let showHighlights: Bool
    private let onTap: (() -> Void)?
    private let onObjectTap: ((DetectedObject) -> Void)?
    
    // Animation configuration
    private let animateMask: Bool
    private let animationPath: [CGPoint]
    private let animationDuration: Double
    private let animationRepeatForever: Bool
    
    // Camera feed - in a real implementation, this would be an AVCaptureSession
    // For this example, we're using a placeholder image
    private let cameraFeedView: AnyView
    
    // Background image name (for preview purposes)
    private let backgroundImageName: String?
    
    // MARK: - Initialization
    
    /// Creates a new CameraPreviewView
    /// - Parameters:
    ///   - showMask: Whether to show a circular mask
    ///   - maskRadius: Radius of the circular mask (as a percentage of the screen width)
    ///   - showHighlights: Whether to show object highlights
    ///   - highlightedObjects: Array of detected objects to highlight
    ///   - animateMask: Whether to animate the mask position
    ///   - animationPath: Array of points defining the animation path for the mask
    ///   - animationDuration: Duration of one complete animation cycle in seconds
    ///   - animationRepeatForever: Whether to repeat the animation indefinitely
    ///   - cameraFeedView: The view to use for the camera feed
    ///   - backgroundImageName: Optional name of a background image to use (for preview purposes)
    ///   - onTap: Action to perform when the view is tapped
    ///   - onObjectTap: Action to perform when a highlighted object is tapped
    public init(
        showMask: Bool = false,
        maskRadius: CGFloat = 0.4,
        showHighlights: Bool = true,
        highlightedObjects: [DetectedObject] = [],
        animateMask: Bool = false,
        animationPath: [CGPoint] = [],
        animationDuration: Double = 3.0,
        animationRepeatForever: Bool = true,
        cameraFeedView: AnyView? = nil,
        backgroundImageName: String? = nil,
        onTap: (() -> Void)? = nil,
        onObjectTap: ((DetectedObject) -> Void)? = nil
    ) {
        self.showMask = showMask
        self.maskRadius = maskRadius
        self.showHighlights = showHighlights
        self._highlightedObjects = State(initialValue: highlightedObjects)
        self.animateMask = animateMask
        
        // Define default animation path
        let defaultPath: [CGPoint] = [
            CGPoint(x: 0.5, y: 0.3),
            CGPoint(x: 0.7, y: 0.5),
            CGPoint(x: 0.5, y: 0.7),
            CGPoint(x: 0.3, y: 0.5)
        ]
        
        self.animationPath = animationPath.isEmpty ? defaultPath : animationPath
        self.animationDuration = animationDuration
        self.animationRepeatForever = animationRepeatForever
        self.backgroundImageName = backgroundImageName
        
        // If we have a background image, use it instead of the provided camera feed view
        if let imageName = backgroundImageName {
            self.cameraFeedView = AnyView(
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            )
        } else {
            self.cameraFeedView = cameraFeedView ?? AnyView(Color.black)
        }
        
        self.onTap = onTap
        self.onObjectTap = onObjectTap
        
        logger.debug("CameraPreviewView initialized with mask: \(showMask), highlights: \(showHighlights), animateMask: \(animateMask)")
    }
    
    /// Creates a new CameraPreviewView with a placeholder color
    /// - Parameters:
    ///   - showMask: Whether to show a circular mask
    ///   - maskRadius: Radius of the circular mask (as a percentage of the screen width)
    ///   - showHighlights: Whether to show object highlights
    ///   - highlightedObjects: Array of detected objects to highlight
    ///   - animateMask: Whether to animate the mask position
    ///   - animationPath: Array of points defining the animation path for the mask (normalized 0-1 coordinates)
    ///   - animationDuration: Duration of one complete animation cycle in seconds
    ///   - animationRepeatForever: Whether to repeat the animation indefinitely
    ///   - placeholderColor: Color to use as a placeholder for the camera feed
    ///   - onTap: Action to perform when the view is tapped
    ///   - onObjectTap: Action to perform when a highlighted object is tapped
    public init(
        showMask: Bool = false,
        maskRadius: CGFloat = 0.4,
        showHighlights: Bool = true,
        highlightedObjects: [DetectedObject] = [],
        animateMask: Bool = false,
        animationPath: [CGPoint] = [],
        animationDuration: Double = 3.0,
        animationRepeatForever: Bool = true,
        placeholderColor: Color = .black,
        onTap: (() -> Void)? = nil,
        onObjectTap: ((DetectedObject) -> Void)? = nil
    ) {
        self.init(
            showMask: showMask,
            maskRadius: maskRadius,
            showHighlights: showHighlights,
            highlightedObjects: highlightedObjects,
            animateMask: animateMask,
            animationPath: animationPath,
            animationDuration: animationDuration,
            animationRepeatForever: animationRepeatForever,
            cameraFeedView: AnyView(placeholderColor),
            backgroundImageName: nil,
            onTap: onTap,
            onObjectTap: onObjectTap
        )
    }
    
    /// Creates a new CameraPreviewView with a background image
    /// - Parameters:
    ///   - showMask: Whether to show a circular mask
    ///   - maskRadius: Radius of the circular mask (as a percentage of the screen width)
    ///   - showHighlights: Whether to show object highlights
    ///   - highlightedObjects: Array of detected objects to highlight
    ///   - animateMask: Whether to animate the mask position
    ///   - animationPath: Array of points defining the animation path for the mask
    ///   - animationDuration: Duration of one complete animation cycle in seconds
    ///   - animationRepeatForever: Whether to repeat the animation indefinitely
    ///   - backgroundImageName: Name of the background image to use
    ///   - onTap: Action to perform when the view is tapped
    ///   - onObjectTap: Action to perform when a highlighted object is tapped
    public init(
        showMask: Bool = false,
        maskRadius: CGFloat = 0.4,
        showHighlights: Bool = true,
        highlightedObjects: [DetectedObject] = [],
        animateMask: Bool = false,
        animationPath: [CGPoint] = [],
        animationDuration: Double = 3.0,
        animationRepeatForever: Bool = true,
        backgroundImageName: String,
        onTap: (() -> Void)? = nil,
        onObjectTap: ((DetectedObject) -> Void)? = nil
    ) {
        self.init(
            showMask: showMask,
            maskRadius: maskRadius,
            showHighlights: showHighlights,
            highlightedObjects: highlightedObjects,
            animateMask: animateMask,
            animationPath: animationPath,
            animationDuration: animationDuration,
            animationRepeatForever: animationRepeatForever,
            cameraFeedView: nil,
            backgroundImageName: backgroundImageName,
            onTap: onTap,
            onObjectTap: onObjectTap
        )
    }
    
    /// Creates a new CameraPreviewView with a live camera feed
    /// - Parameters:
    ///   - showMask: Whether to show a circular mask
    ///   - maskRadius: Radius of the circular mask (as a percentage of the screen width)
    ///   - showHighlights: Whether to show object highlights
    ///   - highlightedObjects: Array of detected objects to highlight
    ///   - animateMask: Whether to animate the mask position
    ///   - animationPath: Array of points defining the animation path for the mask
    ///   - animationDuration: Duration of one complete animation cycle in seconds
    ///   - animationRepeatForever: Whether to repeat the animation indefinitely
    ///   - cameraPosition: The position of the camera to use (front or back)
    ///   - onTap: Action to perform when the view is tapped
    ///   - onObjectTap: Action to perform when a highlighted object is tapped
    public init(
        showMask: Bool = false,
        maskRadius: CGFloat = 0.4,
        showHighlights: Bool = true,
        highlightedObjects: [DetectedObject] = [],
        animateMask: Bool = false,
        animationPath: [CGPoint] = [],
        animationDuration: Double = 3.0,
        animationRepeatForever: Bool = true,
        cameraPosition: AVCaptureDevice.Position = .back,
        onTap: (() -> Void)? = nil,
        onObjectTap: ((DetectedObject) -> Void)? = nil
    ) {
        // Create the camera view
        let cameraView = CameraFeedView(position: cameraPosition)
        
        // Call the main initializer with the camera feed view
        self.showMask = showMask
        self.maskRadius = maskRadius
        self.showHighlights = showHighlights
        self._highlightedObjects = State(initialValue: highlightedObjects)
        self.animateMask = animateMask
        
        // Define default animation path
        let defaultPath: [CGPoint] = [
            CGPoint(x: 0.5, y: 0.3),
            CGPoint(x: 0.7, y: 0.5),
            CGPoint(x: 0.5, y: 0.7),
            CGPoint(x: 0.3, y: 0.5)
        ]
        
        self.animationPath = animationPath.isEmpty ? defaultPath : animationPath
        self.animationDuration = animationDuration
        self.animationRepeatForever = animationRepeatForever
        self.backgroundImageName = nil
        self.cameraFeedView = AnyView(cameraView)
        self.onTap = onTap
        self.onObjectTap = onObjectTap
        
        logger.trace("CameraPreviewView initialized with camera position: \(cameraPosition.rawValue)")
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera feed (or placeholder)
                cameraFeedView
                    .edgesIgnoringSafeArea(.all)
                
                // Optional mask overlay
                if showMask {
                    maskOverlay(geometry: geometry)
                }
                
                // Object highlights
                if showHighlights {
                    objectHighlightsOverlay(geometry: geometry)
                }
                
                // Focus indicators and range finders
                focusIndicatorsOverlay(geometry: geometry)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                logger.debug("Camera preview tapped")
                onTap?()
            }
            .onAppear {
                // Initialize mask position to center of screen
                if maskPosition == .zero {
                    maskPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Start mask animation if enabled
                if showMask && animateMask {
                    startMaskAnimation()
                }
                
                logger.debug("CameraPreviewView appeared with size: \(geometry.size.width) x \(geometry.size.height)")
            }
            .onChange(of: animationProgress) { newValue in
                if showMask && animateMask {
                    updateMaskPosition(geometry: geometry)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Creates the mask overlay
    private func maskOverlay(geometry: GeometryProxy) -> some View {
        let actualMaskRadius = geometry.size.width * maskRadius
        
        return ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            // Circular cutout
            Circle()
                .position(maskPosition)
                .frame(width: actualMaskRadius * 2, height: actualMaskRadius * 2)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
    
    /// Creates the object highlights overlay
    private func objectHighlightsOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(highlightedObjects) { object in
                objectHighlight(object: object, geometry: geometry)
            }
        }
    }
    
    /// Creates a highlight for a single object
    private func objectHighlight(object: DetectedObject, geometry: GeometryProxy) -> some View {
        let rect = object.boundingBox.scaled(to: geometry.size)
        
        return ZStack {
            // Bounding box
            RoundedRectangle(cornerRadius: 8)
                .stroke(object.color, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
            
            // Label at the top
            Text(object.label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(object.color.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(4)
                .offset(y: -rect.height / 2 - 12)
            
            // Confidence score at the bottom
            if let confidence = object.confidence {
                Text("\(Int(confidence * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .offset(y: rect.height / 2 + 12)
            }
        }
        .position(x: rect.midX, y: rect.midY)
        .contentShape(Rectangle())
        .onTapGesture {
            logger.debug("Object tapped: \(object.label)")
            onObjectTap?(object)
        }
    }
    
    /// Creates the focus indicators overlay
    private func focusIndicatorsOverlay(geometry: GeometryProxy) -> some View {
        ZStack {
            // Center focus indicator
            Group {
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 80, height: 80)
                
                // Cross hairs
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 1)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1, height: 20)
            }
            .opacity(0.7)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            // Range finder lines
            Group {
                // Horizontal range finder
                HStack(spacing: 4) {
                    ForEach(0..<20) { i in
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: i % 5 == 0 ? 12 : 6, height: 1)
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 50)
                
                // Vertical range finder
                VStack(spacing: 4) {
                    ForEach(0..<10) { i in
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: i % 5 == 0 ? 12 : 6)
                    }
                }
                .position(x: geometry.size.width / 2 + 50, y: geometry.size.height / 2)
            }
            .opacity(0.5)
        }
    }
    
    // MARK: - Animation Methods
    
    /// Starts the mask animation
    private func startMaskAnimation() {
        let animation = Animation.linear(duration: animationDuration)
        let repeatingAnimation = animationRepeatForever ? animation.repeatForever(autoreverses: false) : animation
        
        withAnimation(repeatingAnimation) {
            animationProgress = 1.0
        }
    }
    
    /// Updates the mask position based on the animation progress
    private func updateMaskPosition(geometry: GeometryProxy) {
        guard !animationPath.isEmpty else { return }
        
        // Calculate the position along the animation path based on progress
        let pathCount = animationPath.count
        let totalProgress = animationProgress * Double(pathCount)
        let segmentIndex = Int(totalProgress) % pathCount
        let segmentProgress = totalProgress - Double(segmentIndex)
        
        let currentPoint = animationPath[segmentIndex]
        let nextPoint = animationPath[(segmentIndex + 1) % pathCount]
        
        // Interpolate between current and next point
        let x = currentPoint.x + (nextPoint.x - currentPoint.x) * CGFloat(segmentProgress)
        let y = currentPoint.y + (nextPoint.y - currentPoint.y) * CGFloat(segmentProgress)
        
        // Convert normalized coordinates (0-1) to screen coordinates
        maskPosition = CGPoint(
            x: x * geometry.size.width,
            y: y * geometry.size.height
        )
    }
    
    // MARK: - Public Methods
    
    /// Updates the highlighted objects
    /// - Parameter objects: The new objects to highlight
    public func updateHighlightedObjects(_ objects: [DetectedObject]) {
        highlightedObjects = objects
        logger.debug("Updated highlighted objects: \(objects.count) objects")
    }
}

// MARK: - Camera Feed View

#if os(macOS)
/// A SwiftUI view that displays a live camera feed using AVFoundation for macOS
public struct CameraFeedView: NSViewRepresentable {
    // MARK: - Properties
    
    private let position: AVCaptureDevice.Position
    private let captureSession = AVCaptureSession()
    private let logger = Logger(subsystem: "com.record-thing", category: "ui")
    
    // MARK: - Initialization
    
    public init(position: AVCaptureDevice.Position = .back) {
        self.position = position
        setupCaptureSession()
    }
    
    // MARK: - NSViewRepresentable
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer?.addSublayer(previewLayer)
        
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = nsView.layer?.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
    
    // MARK: - Setup
    
    private func setupCaptureSession() {
        // Run this on a background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.beginConfiguration()
            
            // Set up the capture device
            guard let captureDevice = self.bestCamera(for: self.position) else {
                self.logger.error("Failed to get capture device for position: \(self.position.rawValue)")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Set up the device input
            guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                self.logger.error("Failed to create device input for device: \(captureDevice.localizedName)")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Add the device input to the session
            if self.captureSession.canAddInput(deviceInput) {
                self.captureSession.addInput(deviceInput)
            } else {
                self.logger.error("Could not add device input to capture session")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Set up the video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            
            // Add the video output to the session
            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
            } else {
                self.logger.error("Could not add video output to capture session")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Commit the configuration
            self.captureSession.commitConfiguration()
            
            // Start the session
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                self.logger.debug("Camera capture session started")
            }
        }
    }
    
    /// Returns the best available camera for the given position
    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // On macOS, use the discovery session to find cameras
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        
        // Get all devices matching the criteria
        let devices = discoverySession.devices
        
        // Return the first device that matches the position
        return devices.first { $0.position == position } ?? devices.first
    }
    
    // MARK: - Cleanup
    
    /// Stops the capture session
    public func stopCaptureSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
            logger.debug("Camera capture session stopped")
        }
    }
}
#else
/// A SwiftUI view that displays a live camera feed using AVFoundation for iOS
public struct CameraFeedView: UIViewRepresentable {
    // MARK: - Properties
    
    private let position: AVCaptureDevice.Position
    private let captureSession = AVCaptureSession()
    private let logger = Logger(subsystem: "com.record-thing", category: "ui")
    
    // MARK: - Initialization
    
    public init(position: AVCaptureDevice.Position = .back) {
        self.position = position
        setupCaptureSession()
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
    
    // MARK: - Setup
    
    private func setupCaptureSession() {
        // Run this on a background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.beginConfiguration()
            
            // Set up the capture device
            guard let captureDevice = self.bestCamera(for: self.position) else {
                self.logger.error("Failed to get capture device for position: \(self.position.rawValue)")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Set up the device input
            guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                self.logger.error("Failed to create device input for device: \(captureDevice.localizedName)")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Add the device input to the session
            if self.captureSession.canAddInput(deviceInput) {
                self.captureSession.addInput(deviceInput)
            } else {
                self.logger.error("Could not add device input to capture session")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Set up the video output
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
            
            // Add the video output to the session
            if self.captureSession.canAddOutput(videoOutput) {
                self.captureSession.addOutput(videoOutput)
            } else {
                self.logger.error("Could not add video output to capture session")
                self.captureSession.commitConfiguration()
                return
            }
            
            // Commit the configuration
            self.captureSession.commitConfiguration()
            
            // Start the session
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                self.logger.debug("Camera capture session started")
            }
        }
    }
    
    /// Returns the best available camera for the given position
    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // First try to get a device with the Ultra Wide camera
        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: position) {
            return ultraWideCamera
        }
        
        // If Ultra Wide is not available, try to get a device with the Wide camera
        if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return wideCamera
        }
        
        // If neither is available, fall back to any available camera for the given position
        return AVCaptureDevice.default(for: .video)
    }
    
    // MARK: - Cleanup
    
    /// Stops the capture session
    public func stopCaptureSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
            logger.debug("Camera capture session stopped")
        }
    }
}
#endif

// MARK: - Supporting Types

/// Represents a detected object in the camera feed
public struct DetectedObject: Identifiable {
    public let id: UUID
    public let label: String
    public let boundingBox: CGRect // Normalized coordinates (0-1)
    public let confidence: Float?
    public let color: Color
    
    public init(
        id: UUID = UUID(),
        label: String,
        boundingBox: CGRect,
        confidence: Float? = nil,
        color: Color = .red
    ) {
        self.id = id
        self.label = label
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.color = color
    }
}

// MARK: - Extensions

extension CGRect {
    /// Scales the normalized rect (0-1) to the given size
    func scaled(to size: CGSize) -> CGRect {
        CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.width * size.width,
            height: self.height * size.height
        )
    }
}

// MARK: - Preview
#if DEBUG
struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic camera preview
            CameraPreviewView(
                placeholderColor: Color.gray.opacity(0.8)
            )
            .previewDisplayName("Basic Preview")
            
            // Camera preview with static mask
            CameraPreviewView(
                showMask: true,
                maskRadius: 0.3,
                placeholderColor: Color.gray.opacity(0.8)
            )
            .previewDisplayName("With Static Mask")
            
            // Camera preview with animated mask
            CameraPreviewView(
                showMask: true,
                maskRadius: 0.3,
                animateMask: true,
                animationPath: [
                    CGPoint(x: 0.3, y: 0.3),
                    CGPoint(x: 0.7, y: 0.3),
                    CGPoint(x: 0.7, y: 0.7),
                    CGPoint(x: 0.3, y: 0.7)
                ],
                animationDuration: 5.0,
                placeholderColor: Color.gray.opacity(0.8)
            )
            .previewDisplayName("With Animated Mask")
            
            // Camera preview with object highlights
            CameraPreviewView(
                showHighlights: true,
                highlightedObjects: [
                    DetectedObject(
                        label: "Watch",
                        boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.2, height: 0.1),
                        confidence: 0.92,
                        color: .green
                    ),
                    DetectedObject(
                        label: "Bag",
                        boundingBox: CGRect(x: 0.6, y: 0.6, width: 0.25, height: 0.2),
                        confidence: 0.85,
                        color: .blue
                    )
                ],
                placeholderColor: Color.gray.opacity(0.8)
            )
            .previewDisplayName("With Highlights")
            
            // Camera preview with both animated mask and highlights
            CameraPreviewView(
                showMask: true,
                maskRadius: 0.3,
                showHighlights: true,
                highlightedObjects: [
                    DetectedObject(
                        label: "Watch",
                        boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.2, height: 0.1),
                        confidence: 0.92,
                        color: .green
                    ),
                    DetectedObject(
                        label: "Bag",
                        boundingBox: CGRect(x: 0.6, y: 0.6, width: 0.25, height: 0.2),
                        confidence: 0.85,
                        color: .blue
                    )
                ],
                animateMask: true,
                placeholderColor: Color.gray.opacity(0.8)
            )
            .previewDisplayName("With Mask & Highlights")
            
            // Camera preview with mountain bike image
            CameraPreviewView(
                showMask: true,
                maskRadius: 0.3,
                showHighlights: true,
                highlightedObjects: [
                    DetectedObject(
                        label: "Electric Mountain Bike",
                        boundingBox: CGRect(x: 0.3, y: 0.4, width: 0.4, height: 0.3),
                        confidence: 0.98,
                        color: .green
                    )
                ],
                animateMask: true,
                backgroundImageName: "thepia_a_high-end_electric_mountain_bike_1"
            )
            .previewDisplayName("Mountain Bike")
        }
    }
}
#endif

