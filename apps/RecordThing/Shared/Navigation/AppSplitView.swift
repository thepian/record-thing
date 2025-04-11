import SwiftUI
import RecordLib
import SwiftUIIntrospect

struct EvidenceListItem: View {
    let evidence: EvidencePiece
    
    var body: some View {
        HStack {
//                evidence.type.icon
//                    .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(evidence.title)
                    .font(.headline)
                Text(evidence.metadata["type"] ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AppSplitView<DetailContent : View>: View {
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var path: NavigationPath
    @ObservedObject var recordedThingViewModel: RecordedThingViewModel
    @ObservedObject var captureService: CaptureService
    @ObservedObject var cameraViewModel: CameraViewModel
    let designSystem: DesignSystemSetup
    let detailContent: DetailContent
    
    init(
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        path: Binding<NavigationPath>,
        recordedThingViewModel: RecordedThingViewModel,
        cameraViewModel: CameraViewModel,
        captureService: CaptureService,
        designSystem: DesignSystemSetup,
        @ViewBuilder detailContent: () -> DetailContent
    ) {
        self._columnVisibility = columnVisibility
        self._path = path
        self.recordedThingViewModel = recordedThingViewModel
        self.cameraViewModel = cameraViewModel
        self.captureService = captureService
        self.designSystem = designSystem
        self.detailContent = detailContent()
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            ZStack {
                // Gradient background
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color.white.opacity(0.7),
//                        Color.white.opacity(0.4)
//                    ]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .overlay(
//                    // Subtle texture
//                    Image(systemName: "circle.grid.3x3.fill")
//                        .foregroundColor(.white.opacity(0.1))
//                        .scaleEffect(2)
//                )
                
                // Blur effect
//                VisualEffectView()
                
                List {
                    Section("Recent Evidence") {
                        ForEach(recordedThingViewModel.pieces) { evidence in
                            EvidenceListItem(evidence: evidence)
                        }
                    }
                    
                    Section("Actions") {
                        Button(action: {
                            recordedThingViewModel.reviewing.toggle()
                        }) {
                            Label("Review Evidence", systemImage: "photo.stack")
                        }
                    }
                    
                    Section("Capture") {
                        CameraSwitcher(captureService: captureService, designSystem: designSystem)
                        
                        CameraSubduedSwitcher(captureService: captureService, designSystem: designSystem)
                        
                        CaptureServiceInfo(captureService: captureService)
                    }
                }
                .listStyle(.sidebar)
//                .scrollContentBackground(.hidden) // Hide default background
            }
            .navigationTitle("Record Thing")
            .toolbar {
                #if os(macOS)
                ToolbarItem {
                    DeveloperSidebar(
                        captureService: captureService,
                        cameraViewModel: cameraViewModel,
                        isCompact: true
                    )
                }
                #else
                ToolbarItem(placement: .navigationBarTrailing) {
                    DeveloperSidebar(
                        captureService: captureService,
                        cameraViewModel: cameraViewModel,
                        isCompact: true
                    )
                }
                #endif
            }
        } detail: {
            detailContent
        }
        #if os(iOS)
        // https://github.com/davdroman/NavigationSplitViewRemoveBackgrounds/blob/main/NavigationSplitViewRemoveBackgrounds.swiftpm/MyApp.swift
        .introspect(.navigationSplitView, on: .iOS(.v16, .v17, .v18)) { split in
            let removeBackgrounds = {
                split.viewControllers.forEach { controller in
                    controller.parent?.view.backgroundColor = .clear
                    controller.view.clearBackgrounds()
                }
            }
            /* We need to restrain the bits being made transparent
             
            removeBackgrounds() // run now...
            DispatchQueue.main.async(execute: removeBackgrounds) // ... and on the next run loop pass
             */
        }
        #endif
    }
}

extension UIView {
    fileprivate func clearBackgrounds() {
        backgroundColor = .clear
        for subview in subviews {
            subview.clearBackgrounds()
        }
    }
}


// VisualEffectView for macOS
#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // No updates needed
    }
}
#else
struct VisualEffectView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No updates needed
    }
}
#endif

#if DEBUG
struct AppSplitView_Previews: PreviewProvider {
    static var previews: some View {
        AppSplitView(
            columnVisibility: .constant(.automatic),
            path: .constant(NavigationPath()),
            recordedThingViewModel: MockedRecordedThingViewModel.createDefault(),
            cameraViewModel: CameraViewModel(),
            captureService: CaptureService(),
            designSystem: .light
        ) {
            Text("Detail Content")
        }
    }
}
#endif 
