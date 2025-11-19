import Foundation
import os.log

#if canImport(UIKit)
  import UIKit
#endif

/// Memory monitoring and management for RecordThing app
/// Helps prevent OOM crashes especially on memory-constrained devices like iPhone Mini
public class MemoryMonitor: ObservableObject {

  // MARK: - Singleton

  public static let shared = MemoryMonitor()

  // MARK: - Properties

  private let logger = Logger(subsystem: "com.thepia.recordthing", category: "MemoryMonitor")

  @Published public var currentMemoryUsage: UInt64 = 0
  @Published public var memoryPressureLevel: MemoryPressureLevel = .normal
  @Published public var isMemoryWarningActive: Bool = false

  // Memory thresholds (in MB)
  private let warningThreshold: UInt64 = 200 * 1024 * 1024  // 200MB
  private let criticalThreshold: UInt64 = 300 * 1024 * 1024  // 300MB

  // MARK: - Memory Pressure Levels

  public enum MemoryPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    case emergency = "Emergency"

    var color: String {
      switch self {
      case .normal: return "green"
      case .warning: return "yellow"
      case .critical: return "orange"
      case .emergency: return "red"
      }
    }
  }

  // MARK: - Initialization

  private init() {
    startMonitoring()
    setupMemoryWarningObserver()
  }

  // MARK: - Public Methods

  /// Get current memory usage in bytes
  public func getCurrentMemoryUsage() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count)
      }
    }

    if kerr == KERN_SUCCESS {
      return info.resident_size
    } else {
      logger.error("Failed to get memory usage: \(kerr)")
      return 0
    }
  }

  /// Get available memory in bytes
  public func getAvailableMemory() -> UInt64 {
    var info = vm_statistics64()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        host_statistics64(
          mach_host_self(),
          HOST_VM_INFO64,
          $0,
          &count)
      }
    }

    if kerr == KERN_SUCCESS {
      let pageSize = UInt64(vm_page_size)
      return (UInt64(info.free_count) + UInt64(info.inactive_count)) * pageSize
    } else {
      logger.error("Failed to get available memory: \(kerr)")
      return 0
    }
  }

  /// Force memory cleanup
  public func performMemoryCleanup() {
    logger.info("Performing memory cleanup...")

    // Clear image caches
    #if canImport(UIKit)
      URLCache.shared.removeAllCachedResponses()
    #endif

    // Trigger garbage collection
    autoreleasepool {
      // Force deallocation of autorelease objects
    }

    // Log memory usage after cleanup
    updateMemoryUsage()
    logger.info(
      "Memory cleanup completed. Current usage: \(self.formatBytes(self.currentMemoryUsage))")
  }

  /// Check if device is memory constrained (like iPhone Mini)
  public func isMemoryConstrainedDevice() -> Bool {
    #if canImport(UIKit)
      let totalMemory = ProcessInfo.processInfo.physicalMemory
      // Consider devices with 4GB or less as memory constrained
      return totalMemory <= 4 * 1024 * 1024 * 1024
    #else
      return false
    #endif
  }

  /// Get device memory info
  public func getDeviceMemoryInfo() -> (total: UInt64, available: UInt64, used: UInt64) {
    let total = ProcessInfo.processInfo.physicalMemory
    let available = getAvailableMemory()
    let used = getCurrentMemoryUsage()
    return (total: total, available: available, used: used)
  }

  // MARK: - Private Methods

  private func startMonitoring() {
    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      self?.updateMemoryUsage()
    }
  }

  private func updateMemoryUsage() {
    let usage = getCurrentMemoryUsage()

    DispatchQueue.main.async {
      self.currentMemoryUsage = usage
      self.updateMemoryPressureLevel(usage)
    }
  }

  private func updateMemoryPressureLevel(_ usage: UInt64) {
    let newLevel: MemoryPressureLevel

    if usage > criticalThreshold {
      newLevel = .emergency
    } else if usage > warningThreshold {
      newLevel = .critical
    } else if usage > warningThreshold / 2 {
      newLevel = .warning
    } else {
      newLevel = .normal
    }

    if newLevel != memoryPressureLevel {
      memoryPressureLevel = newLevel
      logger.info("Memory pressure level changed to: \(newLevel.rawValue)")

      // Trigger cleanup on high pressure
      if newLevel == .critical || newLevel == .emergency {
        performMemoryCleanup()

        // Post notification for other components to reduce memory usage
        NotificationCenter.default.post(
          name: .memoryPressureHigh,
          object: nil,
          userInfo: ["level": newLevel]
        )
      }
    }
  }

  private func setupMemoryWarningObserver() {
    #if canImport(UIKit)
      NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleMemoryWarning()
      }
    #endif
  }

  private func handleMemoryWarning() {
    logger.warning("Received memory warning from system")
    isMemoryWarningActive = true

    // Perform aggressive cleanup
    performMemoryCleanup()

    // Reset warning flag after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      self.isMemoryWarningActive = false
    }
  }

  private func formatBytes(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .memory
    return formatter.string(fromByteCount: Int64(bytes))
  }
}

// MARK: - Notification Names

extension Notification.Name {
  public static let memoryPressureHigh = Notification.Name("memoryPressureHigh")
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
  import SwiftUI

  public struct MemoryMonitorView: View {
    @StateObject private var monitor = MemoryMonitor.shared

    public init() {}

    public var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Memory Monitor")
            .font(.headline)
          Spacer()
          Circle()
            .fill(colorForLevel(monitor.memoryPressureLevel))
            .frame(width: 12, height: 12)
        }

        let memoryInfo = monitor.getDeviceMemoryInfo()

        VStack(alignment: .leading, spacing: 4) {
          Text("Current Usage: \(formatBytes(monitor.currentMemoryUsage))")
            .font(.caption)
          Text("Available: \(formatBytes(memoryInfo.available))")
            .font(.caption)
          Text("Total Device: \(formatBytes(memoryInfo.total))")
            .font(.caption)
          Text("Pressure: \(monitor.memoryPressureLevel.rawValue)")
            .font(.caption)
            .foregroundColor(colorForLevel(monitor.memoryPressureLevel))

          if monitor.isMemoryConstrainedDevice() {
            Text("⚠️ Memory Constrained Device")
              .font(.caption)
              .foregroundColor(.orange)
          }

          if monitor.isMemoryWarningActive {
            Text("🚨 Memory Warning Active")
              .font(.caption)
              .foregroundColor(.red)
          }
        }

        Button("Force Cleanup") {
          monitor.performMemoryCleanup()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .cornerRadius(8)
    }

    private func colorForLevel(_ level: MemoryMonitor.MemoryPressureLevel) -> Color {
      switch level {
      case .normal: return .green
      case .warning: return .yellow
      case .critical: return .orange
      case .emergency: return .red
      }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
      let formatter = ByteCountFormatter()
      formatter.allowedUnits = [.useMB, .useGB]
      formatter.countStyle = .memory
      return formatter.string(fromByteCount: Int64(bytes))
    }
  }
#endif
