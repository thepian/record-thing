import RecordLib
import SwiftUI
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

struct AppSplitView<DetailContent: View>: View {
  @State private var preferredColumn = NavigationSplitViewColumn.detail
  @Binding var columnVisibility: NavigationSplitViewVisibility
  @Binding var path: NavigationPath
  @Binding var lifecycleView: LifecycleView
  @ObservedObject var evidenceViewModel: EvidenceViewModel
  @ObservedObject var captureService: CaptureService
  @ObservedObject var cameraViewModel: CameraViewModel
  @Environment(\.assetsViewModel) var assetsViewModel
  let designSystem: DesignSystemSetup
  let detailContent: DetailContent

  init(
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    lifecycleView: Binding<LifecycleView>,
    path: Binding<NavigationPath>,
    evidenceViewModel: EvidenceViewModel,
    cameraViewModel: CameraViewModel,
    captureService: CaptureService,
    designSystem: DesignSystemSetup,
    @ViewBuilder detailContent: () -> DetailContent
  ) {
    self._columnVisibility = columnVisibility
    self._path = path
    self._lifecycleView = lifecycleView
    self.evidenceViewModel = evidenceViewModel
    self.cameraViewModel = cameraViewModel
    self.captureService = captureService
    self.designSystem = designSystem
    self.detailContent = detailContent()
  }

  #if os(macOS)
    var macosList: some View {
      List(selection: $lifecycleView) {
        NavigationLink(value: LifecycleView.record) {
          Label("Record", systemImage: "camera")
        }
        .accessibilityLabel("Record")

        NavigationLink(value: LifecycleView.assets) {
          Label("Assets", systemImage: "square.3.layers.3d")
        }
        .accessibilityLabel("Assets")

        NavigationLink(value: LifecycleView.actions) {
          Label("Actions", systemImage: "signature")
        }
        .accessibilityLabel("Actions")

        NavigationLink(value: LifecycleView.settings) {
          Label("Settings", systemImage: "gear")
        }
        .accessibilityLabel("Settings")

        NavigationLink {
          ThingsMenu()
        } label: {
          Label("Things", systemImage: "square.3.layers.3d")
        }

        NavigationLink {
          EvidenceTypeMenu()
        } label: {
          Label("Evidence Type", systemImage: "square.3.layers.3d")
        }

        Section("Actions") {
          Button(action: {
            evidenceViewModel.reviewing.toggle()
          }) {
            Label("Review Evidence", systemImage: "photo.stack")
          }
        }
      }
      .listStyle(.sidebar)
    }
  #endif

  var iosList: some View {
    List {
      Button(action: { lifecycleView = .record }) {
        Label("Record", systemImage: "camera")
      }
      .accessibilityLabel("Record")

      Button(action: { lifecycleView = .assets }) {
        Label("Assets", systemImage: "square.3.layers.3d")
      }
      .accessibilityLabel("Assets")

      Button(action: { lifecycleView = .actions }) {
        Label("Actions", systemImage: "signature")
      }
      .accessibilityLabel("Actions")

      Button(action: { lifecycleView = .settings }) {
        Label("Settings", systemImage: "gear")
      }
      .accessibilityLabel("Settings")

      NavigationLink {
        ThingsMenu()
      } label: {
        Label("Things", systemImage: "square.3.layers.3d")
      }

      NavigationLink {
        EvidenceTypeMenu()
      } label: {
        Label("Evidence Type", systemImage: "square.3.layers.3d")
      }

      Section("Actions") {
        Button(action: {
          evidenceViewModel.reviewing.toggle()
        }) {
          Label("Review Evidence", systemImage: "photo.stack")
        }
      }
    }
    .listStyle(.sidebar)
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $columnVisibility, preferredCompactColumn: $preferredColumn
    ) {
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
        #if os(macOS)
          macosList
        #else
          iosList
        #endif
      }
      .navigationTitle("Record Thing")
    } detail: {
      detailContent
    }
    .navigationSplitViewStyle(.balanced)
    #if os(macOS)
      .toolbar(.visible, for: .windowToolbar)
    #else
      .toolbar(.visible, for: .navigationBar, .tabBar)
    #endif
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

#if os(iOS)
  extension UIView {
    fileprivate func clearBackgrounds() {
      backgroundColor = .clear
      for subview in subviews {
        subview.clearBackgrounds()
      }
    }
  }
#endif

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
      @StateObject var assetsViewModel = AssetsViewModel()

      AppSplitView(
        columnVisibility: .constant(.detailOnly),
        lifecycleView: .constant(.record),
        path: .constant(NavigationPath()),
        evidenceViewModel: .createDefault(),
        cameraViewModel: CameraViewModel(),
        captureService: CaptureService(),
        designSystem: .light
      ) {
        Text("Detail Content")
      }
      .environment(\.assetsViewModel, assetsViewModel)
      .previewDisplayName("Collapsed")

      AppSplitView(
        columnVisibility: .constant(.automatic),
        lifecycleView: .constant(.record),
        path: .constant(NavigationPath()),
        evidenceViewModel: .createDefault(),
        cameraViewModel: CameraViewModel(),
        captureService: CaptureService(),
        designSystem: .light
      ) {
        Text("Detail Content")
      }
      .environment(\.assetsViewModel, assetsViewModel)
      .previewDisplayName("Expanded")
    }
  }
#endif
