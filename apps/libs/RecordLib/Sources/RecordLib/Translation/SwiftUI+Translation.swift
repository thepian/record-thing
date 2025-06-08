import SwiftUI

// MARK: - SwiftUI Translation Extensions

public extension Text {
    
    /// Create a Text view with a translated string
    /// - Parameter key: Translation key
    /// - Returns: Text view with translated content
    init(translated key: String) {
        self.init(TranslationManager.shared.translate(key))
    }
    
    /// Create a Text view with a translated string and arguments
    /// - Parameters:
    ///   - key: Translation key
    ///   - arguments: Arguments for string interpolation
    /// - Returns: Text view with translated and interpolated content
    init(translated key: String, arguments: CVarArg...) {
        let template = TranslationManager.shared.translate(key)
        self.init(String(format: template, arguments: arguments))
    }
}

public extension String {
    
    /// Get translated version of this string (treating it as a key)
    var translated: String {
        return TranslationManager.shared.translate(self)
    }
    
    /// Get translated version with arguments
    /// - Parameter arguments: Arguments for string interpolation
    /// - Returns: Translated and interpolated string
    func translated(arguments: CVarArg...) -> String {
        let template = TranslationManager.shared.translate(self)
        return String(format: template, arguments: arguments)
    }
}

// MARK: - Translation Key Constants

public struct TranslationKeys {
    
    // MARK: - Common UI
    public static let cancel = "common.cancel"
    public static let save = "common.save"
    public static let delete = "common.delete"
    public static let edit = "common.edit"
    public static let done = "common.done"
    public static let close = "common.close"
    public static let back = "common.back"
    public static let next = "common.next"
    public static let previous = "common.previous"
    public static let loading = "common.loading"
    public static let error = "common.error"
    public static let success = "common.success"
    public static let warning = "common.warning"
    
    // MARK: - Settings
    public static let settings = "settings.title"
    public static let account = "settings.account"
    public static let plan = "settings.plan"
    public static let sync = "settings.sync"
    public static let privacy = "settings.privacy"
    public static let about = "settings.about"
    public static let development = "settings.development"
    
    // MARK: - Sync & Backup
    public static let autoSync = "sync.auto_sync"
    public static let selectiveSync = "sync.selective_sync"
    public static let iCloudBackup = "sync.icloud_backup"
    public static let syncNow = "sync.sync_now"
    public static let lastSync = "sync.last_sync"
    public static let syncDocuments = "sync.sync_documents"
    
    // MARK: - Privacy
    public static let contributeToAI = "privacy.contribute_to_ai"
    public static let privateRecordings = "privacy.private_recordings"
    public static let privacyPolicy = "privacy.privacy_policy"
    
    // MARK: - Demo Mode
    public static let demoMode = "demo.demo_mode"
    public static let resetDemoData = "demo.reset_data"
    public static let updateDemoData = "demo.update_data"
    
    // MARK: - Database
    public static let backupDatabase = "database.backup"
    public static let reloadDatabase = "database.reload"
    public static let resetDatabase = "database.reset"
    public static let databaseDebug = "database.debug"
    
    // MARK: - Translation Settings
    public static let useSourceTranslations = "translation.use_source"
    
    // MARK: - Plans
    public static let freePlan = "plan.free"
    public static let premiumPlan = "plan.premium"
    public static let upgrade = "plan.upgrade"
    public static let active = "plan.active"
    
    // MARK: - Camera
    public static let cameraStream = "camera.stream"
    public static let powerMode = "camera.power_mode"
    public static let captureServiceInfo = "camera.capture_service_info"
    
    // MARK: - Help
    public static let helpSupport = "help.help_support"
    public static let version = "help.version"
    public static let build = "help.build"
}

// MARK: - Translation View Modifier

public struct TranslationEnvironment: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .translationSettingsChanged)) { _ in
                // Reload translations when settings change
                TranslationManager.shared.reloadDatabase()
            }
    }
}

public extension View {
    
    /// Apply translation environment to handle translation updates
    func translationEnvironment() -> some View {
        modifier(TranslationEnvironment())
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let translationSettingsChanged = Notification.Name("translationSettingsChanged")
}
