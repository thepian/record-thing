import Foundation
import ZIPFoundation
import WebKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public class WebContentManager {
    public static let shared = WebContentManager()
    
    private let fileManager = FileManager.default
    private let contentDirectoryName = "FlowsContent"
    
    public var contentDirectoryURL: URL? {
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupportURL.appendingPathComponent(contentDirectoryName)
    }
    
    public var indexURL: URL? {
        return contentDirectoryURL?.appendingPathComponent("index.html")
    }
    
    private init() {}
    
    public func hasContent() -> Bool {
        guard let indexURL = indexURL else { return false }
        return fileManager.fileExists(atPath: indexURL.path)
    }
    
    public func seed(from zipURL: URL) throws {
        guard let destinationURL = contentDirectoryURL else {
            throw NSError(domain: "WebContentManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine content directory"])
        }
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Clear existing content to ensure clean state
        if fileManager.fileExists(atPath: destinationURL.path) {
             try? fileManager.removeItem(at: destinationURL)
             try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        try fileManager.unzipItem(at: zipURL, to: destinationURL)
    }
    
    public func ensureDirectoryExists() {
        guard let url = contentDirectoryURL else { return }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Seeds the content from the app bundle if available
    public func seedFromBundle() -> Bool {
        // Try to load from Asset Catalog (NSDataAsset)
        // The asset name in Xcode is "offline-cache.zip" (from offline-cache.zip.dataset)
        
        #if canImport(UIKit)
        typealias DataAsset = NSDataAsset
        #elseif canImport(AppKit)
        typealias DataAsset = NSDataAsset
        #endif
        
        guard let asset = DataAsset(name: "offline-cache.zip") else {
            print("WebContentManager: offline-cache.zip not found in Asset Catalog")
            return false
        }
        
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent("offline-cache.zip")
        
        do {
            try asset.data.write(to: tempURL)
            try seed(from: tempURL)
            try? fileManager.removeItem(at: tempURL)
            print("WebContentManager: Seeded content from Asset Catalog")
            return true
        } catch {
            print("WebContentManager: Failed to seed from Asset Catalog: \(error)")
            try? fileManager.removeItem(at: tempURL)
            return false
        }
    }
    
    // MARK: - WebView Cache Management
    
    /// Clears website data for specific domains
    public func clearWebViewCache(for domains: [String], completion: @escaping () -> Void = {}) {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            let recordsToDelete = records.filter { record in
                domains.contains(where: { record.displayName.contains($0) })
            }
            
            if !recordsToDelete.isEmpty {
                print("WebContentManager: Clearing cache for domains: \(recordsToDelete.map { $0.displayName })")
                dataStore.removeData(ofTypes: dataTypes, for: recordsToDelete) {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    /// Seeds cookies from HTTPCookieStorage to WKWebView
    public func seedCookies(from storage: HTTPCookieStorage = .shared, completion: @escaping () -> Void = {}) {
        let dataStore = WKWebsiteDataStore.default()
        let cookies = storage.cookies ?? []
        
        if cookies.isEmpty {
            completion()
            return
        }
        
        let group = DispatchGroup()
        
        for cookie in cookies {
            group.enter()
            dataStore.httpCookieStore.setCookie(cookie) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("WebContentManager: Seeded \(cookies.count) cookies")
            completion()
        }
    }
}
