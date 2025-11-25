import Foundation
import Combine

public enum FeatureFlag: String, CaseIterable, Identifiable {
    case offlineCacheAsset = "use_offline_cache"
    case newOnboarding = "new_onboarding_flow"
    case useNewDatabase = "use_new_database"
    case enableDebugMenu = "enable_debug_menu"
    
    public var id: String { rawValue }
    
    public var defaultValue: Bool {
        switch self {
        case .offlineCacheAsset: return true
        case .newOnboarding: return false
        case .useNewDatabase: return false
        case .enableDebugMenu: return false
        }
    }
    
    public var label: String {
        switch self {
        case .offlineCacheAsset: return "Use offline-cache.zip"
        case .newOnboarding: return "New Onboarding Flow"
        case .useNewDatabase: return "Use New Database"
        case .enableDebugMenu: return "Enable Debug Menu"
        }
    }
}

public protocol FeatureFlagProvider {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

// TODO plug in PostHog
public class LocalProvider: FeatureFlagProvider {
    private let defaults = UserDefaults.standard
    private let prefix = "feature_flag_"
    
    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        // Check if explicitly set in UserDefaults
        if defaults.object(forKey: prefix + flag.rawValue) != nil {
            return defaults.bool(forKey: prefix + flag.rawValue)
        }
        return false // Fallback to next provider or default
    }
    
    public func set(_ flag: FeatureFlag, value: Bool?) {
        if let value = value {
            defaults.set(value, forKey: prefix + flag.rawValue)
        } else {
            defaults.removeObject(forKey: prefix + flag.rawValue)
        }
    }
    
    public func hasOverride(_ flag: FeatureFlag) -> Bool {
        return defaults.object(forKey: prefix + flag.rawValue) != nil
    }
}

public class PostHogProvider: FeatureFlagProvider {
    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        // TODO: Integrate PostHog SDK
        // return PostHogSDK.shared.isFeatureEnabled(flag.rawValue)
        return false
    }
}

public class FeatureFlagService: ObservableObject {
    public static let shared = FeatureFlagService()
    
    private let localProvider = LocalProvider()
    private let remoteProvider = PostHogProvider()
    
    // We publish changes manually when overrides change
    @Published public var lastUpdate: Date = Date()
    
    private init() {}
    
    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        // 1. Check local override
        if localProvider.hasOverride(flag) {
            return localProvider.isEnabled(flag)
        }
        
        // 2. Check remote provider (if implemented)
        // if remoteProvider.isEnabled(flag) { return true }
        
        // 3. Fallback to default
        return flag.defaultValue
    }
    
    // MARK: - Local Overrides
    
    public func setOverride(_ flag: FeatureFlag, value: Bool?) {
        localProvider.set(flag, value: value)
        lastUpdate = Date() // Trigger UI updates
    }
    
    public func hasOverride(_ flag: FeatureFlag) -> Bool {
        return localProvider.hasOverride(flag)
    }
}
