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
        List {

          // This updates content
          NavigationLink {
            if let assetsViewModel = assetsViewModel {
              ThingsGridView(
                viewModel: assetsViewModel, evidenceViewModel: evidenceViewModel, columns: 2
              ) { thing in
                print("Selected thing: \(thing.title ?? "Untitled")")
              }
            } else {
              Text("Missing Assets")
            }
          } label: {
            Label("Assets", systemImage: "square.3.layers.3d")
          }

          NavigationLink {
            Text("iuoptyuptyoiu")
          } label: {
            Label("Actions", systemImage: "signature")
          }

          NavigationLink {
            ImprovedSettingsView()
          } label: {
            Label("Settings", systemImage: "gear")
          }

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

          //                    Section("Recent Evidence") {
          //                        ForEach(evidenceViewModel.pieces) { evidence in
          //                            EvidenceListItem(evidence: evidence)
          //                        }
          //                    }

          Section("Actions") {
            Button(action: {
              evidenceViewModel.reviewing.toggle()
            }) {
              Label("Review Evidence", systemImage: "photo.stack")
            }
          }

          Section("Develop") {
            CameraSwitcher(captureService: captureService, designSystem: designSystem)

            CameraSubduedSwitcher(captureService: captureService, designSystem: designSystem)

            CaptureServiceInfo(captureService: captureService)
          }
        }
        .listStyle(.sidebar)
      }
      .navigationTitle("Record Thing")
      .toolbar {
        ToolbarItem {
          NavigationLink {
            detailContent.onAppear {
              lifecycleView = .record
            }
          } label: {
            Label("Record", systemImage: "camera")
          }
        }
        #if os(macOS)
          ToolbarItem {
            DeveloperToolbar(
              captureService: captureService,
              cameraViewModel: cameraViewModel,
              isCompact: true
            )
          }
        #else
          ToolbarItem(placement: .navigationBarTrailing) {
            DeveloperToolbar(
              captureService: captureService,
              cameraViewModel: cameraViewModel,
              isCompact: true
            )
          }
        #endif
      }
      //        } content: {
      //            // blank content
      //            Button("Detail Only") {
      //                columnVisibility = .detailOnly
      //            }
      //            Button("Double Column") {
      //                columnVisibility = .doubleColumn
      //            }
      //            NavigationLink {
      //                Text("sdfsdfsafd (detail)")
      //            } label: {
      //                Label("123 (D)", systemImage: "gear")
      //            }
      //
    } detail: {
      NavigationStack {
        VStack {
          //                    NavigationLink {
          //                        Text("sdfsdfsafd (detail)")
          //                    } label: {
          //                        Label("123 (D)", systemImage: "gear")
          //                    }
          detailContent
        }
        .navigationDestination(for: NavigationDestination.self) { dest in
          AppSplitDetailView(destination: dest)
        }
      }
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

struct AppSplitDetailView: View {
  let destination: NavigationDestination

  var body: some View {
    Group {
      switch destination {
      case .record(let evidenceId):
        EmptyView()
      case .assets:
        ZStack {
          Text("Assets")
        }
      case .assetsGroup(let groupId):
        EmptyView()
      case .assetsDetail(let assetId):
        EmptyView()
      case .assetsThingDetail(let thingId):
        EmptyView()
      case .assetsEvidenceList(let thingId):
        EmptyView()
      case .assetsThingDetail(let thingId):
        EmptyView()
      case .assetsEvidenceDetail(let thingId, let evidenceId):
        EmptyView()

      // Actions Tab Paths
      case .actions:
        ZStack {
          Text("Actions")
        }
      case .actionsAccount:
        EmptyView()
      case .actionsSettings:
        EmptyView()
      case .actionsHelp:
        EmptyView()
      }

      /*
      switch destination {
      case .thingDetail(let id):
          if let thing = sampleThings.first(where: { $0.id == id }) {
              ThingDetailView(thing: thing)
          }
      case .categoryDetail(let id):
          CategoryDetailView(categoryId: id)
      case .productTypeDetail(let id):
          if let productType = sampleTypes.first(where: { $0.id == id }) {
              ProductTypeDetailView(productType: productType)
          }
      case .feedItem(let id):
          VStack {
              Text("Feed Item \(id)")
                  .font(.title)
          }
      case .favoriteItem(let id):
          VStack {
              Text("Favorite Item \(id)")
                  .font(.title)
          }
      default:
          VStack {
              Text("Tab: \(destination.tab.title)")
                  .font(.headline)
              Text("Destination: \(destination.id)")
                  .font(.subheadline)
          }
      }
      */
    }
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

// MARK: - Improved Settings View

struct ImprovedSettingsView: View {
  @State private var demoModeEnabled = false
  @State private var autoSyncEnabled = false
  @State private var contributeToAI = true
  @State private var showingUpgradeSheet = false
  @State private var showingDatabaseResetAlert = false

  var body: some View {
    List {
      Section {
        HStack {
          Image(systemName: "person.circle.fill")
            .font(.title2)
            .foregroundColor(.accentColor)

          VStack(alignment: .leading) {
            Text("Demo User")
              .font(.headline)
            Text("demo@thepia.com")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          Button("Edit") {
            // Edit account
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }
      } header: {
        Text("Account")
      }

      Section {
        HStack {
          VStack(alignment: .leading) {
            HStack {
              Text("Free Plan")
                .font(.headline)
              Spacer()
            }
            Text("Basic recording and local storage")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Button("Upgrade") {
            showingUpgradeSheet = true
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
        }
      } header: {
        Text("Plan & Billing")
      }

      Section {
        HStack {
          Label("Auto Sync", systemImage: "arrow.triangle.2.circlepath")
          Spacer()
          Toggle("", isOn: $autoSyncEnabled)
            .disabled(true)  // Disabled for free tier
        }

        Button("Sync Now") {
          // Manual sync
        }
        .disabled(true)

      } header: {
        Text("Sync & Backup")
      } footer: {
        Text("Sync features are available with Premium plan.")
      }

      Section {
        HStack {
          Label("Contribute to AI Training", systemImage: "brain")
          Spacer()
          Toggle("", isOn: $contributeToAI)
            .disabled(true)  // Free tier always contributes
        }

        Button("Privacy Policy") {
          // Show privacy policy
        }

      } header: {
        Text("Privacy & Data")
      } footer: {
        Text("Free tier recordings help improve our AI. Upgrade to Premium for privacy controls.")
      }

      Section {
        HStack {
          Label("Demo Mode", systemImage: "play.circle")
          Spacer()
          Toggle("", isOn: $demoModeEnabled)
        }

        if demoModeEnabled {
          Button("Reset Demo Data") {
            // Reset demo data
          }
        }

      } header: {
        Text("Demo Mode")
      } footer: {
        if demoModeEnabled {
          Text("Demo mode limits database modifications and disables cloud sync.")
        } else {
          Text("Enable demo mode to explore the app with sample data.")
        }
      }

      #if DEBUG
        Section {
          Button("Database Debug") {
            // Show database debug
          }

          Button("Backup Database") {
            // Trigger backup
          }

          Button("Reset Database") {
            showingDatabaseResetAlert = true
          }
          .foregroundColor(.red)

        } header: {
          Text("Development")
        } footer: {
          Text("Development tools for debugging and testing.")
        }
      #endif

      Section {
        HStack {
          Text("Version")
          Spacer()
          Text("1.0.0")
            .foregroundColor(.secondary)
        }

        Button("Help & Support") {
          // Show help
        }
      } header: {
        Text("About")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle("Settings")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.large)
    #endif
    .sheet(isPresented: $showingUpgradeSheet) {
      SimpleUpgradeView()
    }
    .alert("Reset Database", isPresented: $showingDatabaseResetAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        // Reset database
      }
    } message: {
      Text("This will permanently delete all your data and reset the app to its initial state.")
    }
  }
}

struct SimpleUpgradeView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Image(systemName: "crown.fill")
          .font(.system(size: 60))
          .foregroundColor(.yellow)

        Text("Upgrade to Premium")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Unlock advanced features and cloud sync")
          .font(.title3)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        Spacer()

        Button("Start Free Trial") {
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Text("$4.99/month after 7-day free trial")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
  }
}

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
      .previewDisplayName("Detail Only")
    }
  }
#endif
