import Foundation
import os

/// Extension to configure logging behavior across the app
extension Logger {
    /// Configure the logging system to omit trace level logs
    public static func configureLogging() {
        // Set the default log level to debug, which will filter out trace logs
        // This is done by setting the OS_ACTIVITY_MODE environment variable
        // to "debug" which will filter out trace logs
        setenv("OS_ACTIVITY_MODE", "debug", 1)
        
        // Log that the configuration has been applied
        let configLogger = Logger(subsystem: "com.record-thing", category: "logging-config")
        configLogger.debug("Logging configured to omit trace level logs")
    }
    
    /// A wrapper for trace logging that can be used to conditionally enable/disable trace logs
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    public func trace(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // Check if trace logging is enabled
        if let traceEnabled = ProcessInfo.processInfo.environment["ENABLE_TRACE_LOGGING"], traceEnabled == "1" {
            // Only log if trace logging is explicitly enabled
            self.debug("\(message) [\(file):\(line)]")
        }
        // Otherwise, do nothing (trace logs are filtered out)
    }
} 