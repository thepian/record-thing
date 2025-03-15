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

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.thepia.RecordThing",
    category: "App"
)

class Model: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    @Published var account: AccountModel?
    
    // Add checkboxItems for RecordedStackAndRequirementsView
    @Published var checkboxItems: [CheckboxItem] = [
        CheckboxItem(text: "Take product photo"),
        CheckboxItem(text: "Scan barcode", isChecked: true),
        CheckboxItem(text: "Capture Sales Receipt")
    ]
    
    var hasAccount: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return userCredential != nil && account != nil
        #endif
    }
    
    @Published var favoriteProductIDs = Set<Things.ID>()
    @Published var selectedThingID: Things.ID?
    @Published var selectedRequestID: Requests.ID?
    @Published var selectedTypeID: EvidenceType.ID?

    @Published var searchString = ""
    
    @Published var isApplePayEnabled = true
    @Published var allRecipesUnlocked = false
//    @Published var unlockAllRecipesProduct: ProductDef?
    
    let defaults = UserDefaults(suiteName: "group.example.recordthing")
    
    private var userCredential: String? {
        get { defaults?.string(forKey: "UserCredential") }
        set { defaults?.setValue(newValue, forKey: "UserCredential") }
    }
    
    private let allProductIdentifiers = Set([Model.unlockAllRecipesIdentifier])
//    private var fetchedProducts: [ProductDef] = []
    private var updatesHandler: Task<Void, Error>? = nil
    
    @Published var loadedLang: String?
    
    init() {
        // Start listening for transaction info updates, like if the user
        // refunds the purchase or if a parent approves a child's request to
        // buy.
        updatesHandler = Task {
//            await listenForStoreUpdates()
        }
        fetchProducts()
        
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
            }
            .store(in: &cancellables)
        }
    }
    
    convenience init(loadedLangConst _loadedLang: String) {
        self.init()
        loadedLang = _loadedLang
    }
    
    deinit {
        updatesHandler?.cancel()
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
    func toggleFavorite(smoothieID: Things.ID) {
        if favoriteProductIDs.contains(smoothieID) {
            favoriteProductIDs.remove(smoothieID)
        } else {
            favoriteProductIDs.insert(smoothieID)
        }
    }
    
//    func isFavorite(product: ProductDef) -> Bool {
//        favoriteProductIDs.contains(product.id)
//    }
    
    func isFavorite(product: EvidenceType) -> Bool {
        favoriteProductIDs.contains(product.fullName)
    }
    
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
    
//    func product(for identifier: String) -> ProductDef? {
//        return fetchedProducts.first(where: { $0.id == identifier })
//    }
        
}

// MARK: - Private Logic

extension Model {
    
    private func fetchProducts() {
        Task { @MainActor in
//            self.fetchedProducts = try await ProductDef.products(for: allProductIdentifiers)
//            self.unlockAllRecipesProduct = self.fetchedProducts
//                .first { $0.id == Model.unlockAllRecipesIdentifier }
            // Check if the user owns all recipes at app launch.
            await self.updateAllRecipesOwned()
        }
    }
    
    @MainActor
    private func updateAllRecipesOwned() async {
//        guard let product = self.unlockAllRecipesProduct else {
//            self.allRecipesUnlocked = false
//            return
//        }
//        guard let entitlement = await product.currentEntitlement,
//              case .verified(_) = entitlement else {
//                  self.allRecipesUnlocked = false
//                  return
//        }
        self.allRecipesUnlocked = true
    }
    
}

// MARK: - Checkbox Items Management

extension Model {
    func toggleCheckboxItem(_ item: CheckboxItem) {
        if let index = checkboxItems.firstIndex(where: { $0.id == item.id }) {
            checkboxItems[index].isChecked.toggle()
            logger.debug("Toggled checkbox item: \(self.checkboxItems[index].text), isChecked: \(self.checkboxItems[index].isChecked)")
        }
    }
    
    func resetCheckboxItems() {
        checkboxItems = [
            CheckboxItem(text: "Take product photo", isChecked: false),
            CheckboxItem(text: "Scan barcode", isChecked: false),
            CheckboxItem(text: "Capture Sales Receipt", isChecked: false)
        ]
    }
    
    func updateCheckboxItems(for category: AssetCategory) {
        // Example of updating checkbox items based on the selected category
        switch category {
        case .watches:
            checkboxItems = [
                CheckboxItem(text: "Take watch photo"),
                CheckboxItem(text: "Scan serial number"),
                CheckboxItem(text: "Capture warranty card")
            ]
        case .bags:
            checkboxItems = [
                CheckboxItem(text: "Take bag photo"),
                CheckboxItem(text: "Scan authenticity code"),
                CheckboxItem(text: "Capture receipt")
            ]
        default:
            // Default items
            checkboxItems = [
                CheckboxItem(text: "Take product photo"),
                CheckboxItem(text: "Scan barcode", isChecked: true),
                CheckboxItem(text: "Capture Sales Receipt")
            ]
        }
    }
}
