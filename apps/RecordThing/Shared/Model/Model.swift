/*
See LICENSE folder for this sample's licensing information.

Abstract:
A model representing all of the data the app needs to display in its interface.
*/

import Foundation
import AuthenticationServices
import os
import Combine
import RecordLib
import SwiftUICore

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing",
    category: "App"
)

// Overall lifecycle for the app
// TODO set using callbacks and define in App, make selectedTab internal
public enum LifecycleView {
    case loading
    case development
    case record
    case assets
    case actions
}


class Model: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published var account: AccountModel?
        
    // Helper method to create system images
    func systemImage(_ name: String) -> Image {
        if let recordImage = RecordImage.systemImage(name) {
            return recordImage.asImage
        }
        return Image(systemName: name) // Fallback
    }
    
    var hasAccount: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return userCredential != nil && account != nil
        #endif
    }
    
    @Published var selectedThingID: Things.ID?
    @Published var selectedRequestID: Requests.ID?
    @Published var selectedTypeID: EvidenceType.ID?

    @Published var searchString = ""
    
    @Published var isApplePayEnabled = true
    
    let defaults = UserDefaults(suiteName: "group.example.recordthing")
    
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
    
    convenience init(loadedLang _loadedLang: Published<String?>.Publisher?) {
        self.init()
        
        if let _loadedLang = _loadedLang {
            _loadedLang.sink { [weak self] newValue in
                self?.loadedLang = newValue
                self?.lifecycleView = .record
            }
            .store(in: &cancellables)
        }
    }
    
    convenience init(loadedLangConst _loadedLang: String) {
        self.init()
        loadedLang = _loadedLang
        lifecycleView = .record
    }
    
    deinit {
    }
    
    func authorizeUser(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result, let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
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
            $0.name.localizedCaseInsensitiveContains(searchString) &&
            $0.name.localizedCaseInsensitiveCompare(searchString) != .orderedSame
        }
    }
}

// MARK: - Store API

extension Model {
    static let unlockAllRecipesIdentifier = "com.example.apple-samplecode.recordthing.unlock-recipes"
    
}
