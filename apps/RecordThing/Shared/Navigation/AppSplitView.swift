import SwiftUI
import RecordLib

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

struct AppSplitView<DetailContent: View>: View {
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
                }
            }
            .listStyle(.sidebar)
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
    }
}

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
