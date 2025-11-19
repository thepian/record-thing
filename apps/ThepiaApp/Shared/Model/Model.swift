/*
See LICENSE folder for this sample's licensing information.

Abstract:
A model representing all of the data the app needs to display in its interface.
*/

import AuthenticationServices
import Combine
import Foundation
import RecordLib
import SwiftUI
import os

private let logger = Logger(
  subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.ThepiaApp",
  category: "App"
)

// Overall lifecycle for the app
// TODO set using callbacks and define in App, make selectedTab internal
public enum LifecycleView: CaseIterable {
  case loading
  case development
  case record // Recording preview on to of app background with tools
  case assets // Assets you care for and have recorded about
  case actions // What you need to act on based on requests and notifications (inbox)
  case settings

  /// Human-readable label for the view
  public var label: String {
    switch self {
    case .loading:
      return "Loading"
    case .development:
      return "Development"
    case .record:
      return "Record"
    case .assets:
      return "Assets"
    case .actions:
      return "Actions"
    case .settings:
      return "Settings"
    }
  }

  /// System image name for the view
  public var imageName: String {
    switch self {
    case .loading:
      return "hourglass"
    case .development:
      return "ladybug"
    case .record:
      return "camera"
    case .assets:
      return "square.3.layers.3d"
    case .actions:
      return "signature"
    case .settings:
      return "gear"
    }
  }
}

final class Model: ObservableObject {
  private var cancellables = Set<AnyCancellable>()
  var primaryView: LifecycleView = .record

  @Published var account: AccountModel?

  // Helper method to create system images
  func systemImage(_ name: String) -> Image {
    if let recordImage = RecordImage.systemImage(name) {
      return recordImage.asImage
    }
    return Image(systemName: name)  // Fallback
  }

  var hasAccount: Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return userCredential != nil && account != nil
    #endif
  }
    
  // Combine isAuthenticated, Camera Enabled, Microphone Enabled
  @Published var requiresOnboarding: Bool = true

  @Published var selectedThingID: Things.ID?
  @Published var selectedRequestID: Requests.ID?
  @Published var selectedTypeID: EvidenceType.ID?
  @Published var selectedStrategistID: Strategists.ID?

  @Published var searchString = ""

  let defaults = UserDefaults(suiteName: "group.example.app")

  private var userCredential: String? {
    get { defaults?.string(forKey: "UserCredential") }
    set { defaults?.setValue(newValue, forKey: "UserCredential") }
  }

  @Published var lifecycleView: LifecycleView = .loading
  @Published var loadedLang: String?

  init() {

    guard let user = userCredential else { return }
    let provider = ASAuthorizationAppleIDProvider()
    provider.getCredentialState(forUserID: user) { state, error in
      if state == .authorized || state == .transferred {
        DispatchQueue.main.async {
          self.createAccount()
        }
      }
    }

  }

  convenience init(loadedLang _loadedLang: Published<String?>.Publisher?, primaryView: LifecycleView = .record) {
    self.init()
    self.lifecycleView = lifecycleView

    if let _loadedLang = _loadedLang {
      _loadedLang.sink { [weak self] newValue in
        self?.loadedLang = newValue
          self?.lifecycleView = self?.primaryView ?? .record
      }
      .store(in: &cancellables)
    }
  }

  convenience init(loadedLangConst _loadedLang: String, primaryView: LifecycleView = .record) {
    self.init()
    self.lifecycleView = lifecycleView
      
    loadedLang = _loadedLang
    lifecycleView = primaryView
  }

  deinit {
  }

  func authorizeUser(_ result: Result<ASAuthorization, Error>) {
    guard case .success(let authorization) = result,
      let credential = authorization.credential as? ASAuthorizationAppleIDCredential
    else {
      if case .failure(let error) = result {
        logger.error("Authentication error: \(error.localizedDescription)")
      }
      return
    }
    DispatchQueue.main.async {
      self.userCredential = credential.user
      self.createAccount()
    }
  }
}

// MARK: - Products & AccountModel

extension Model {
  func createAccount() {
    guard account == nil else { return }
    account = AccountModel()
  }

  func clearUnstampedPoints() {
    account?.clearUnstampedPoints()
  }

  var searchSuggestions: [Evidence] {
    Evidence.all.filter {
      $0.name.localizedCaseInsensitiveContains(searchString)
        && $0.name.localizedCaseInsensitiveCompare(searchString) != .orderedSame
    }
  }
}


// MARK: - Identity

extension Model {
  var identityImage: Image {
    Image("thepia_a_beige_scandinavian_kitchen_table_with_bag")
  }
}
