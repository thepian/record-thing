import RecordLib
import SwiftUI

/// Actions view - aggregate "Actions" flow for phone layout
/// Works similar to notifications or an inbox with calls to action (CTAs) for the user
struct ActionsView: View {
  let captureService: CaptureService?
  let designSystem: DesignSystemSetup?
  let onRecordTapped: (() -> Void)?

  @State private var showingSettings = false
  @State private var showingAccountEdit = false
  @State private var showingTeamManagement = false

  init(
    captureService: CaptureService? = nil, designSystem: DesignSystemSetup? = nil,
    onRecordTapped: (() -> Void)? = nil
  ) {
    self.captureService = captureService
    self.designSystem = designSystem
    self.onRecordTapped = onRecordTapped
  }

  var body: some View {
    NavigationStack {
      List {
        // Call-to-Action Entries Section
        Section {
          // Settings Access CTA
          NavigationLink {
            if let captureService = captureService, let designSystem = designSystem {
              ImprovedSettingsView(
                captureService: captureService,
                designSystem: designSystem
              )
            } else {
              ImprovedSettingsView()
            }
          } label: {
            ActionItemView(
              icon: "gear",
              title: "Settings",
              subtitle: "Configure app preferences and camera settings",
              priority: .normal
            )
          }

          // Account Update CTA
          Button {
            showingAccountEdit = true
          } label: {
            ActionItemView(
              icon: "person.circle",
              title: "Update Account",
              subtitle: "Complete your profile information",
              priority: .high,
              showChevron: false
            )
          }
          .buttonStyle(.plain)

          // Evidence Recording Request CTA
          Button {
            // Navigate to specific recording request
          } label: {
            ActionItemView(
              icon: "camera.fill",
              title: "Record Evidence",
              subtitle: "Capture requested documentation",
              priority: .urgent,
              showChevron: false
            )
          }
          .buttonStyle(.plain)

          // Team Invitation CTA
          Button {
            showingTeamManagement = true
          } label: {
            ActionItemView(
              icon: "person.2.fill",
              title: "Team Invitation",
              subtitle: "Join the 'Project Alpha' team",
              priority: .normal,
              showChevron: false
            )
          }
          .buttonStyle(.plain)

        } header: {
          Text("Actions")
        }

        // Agreements Section
        Section {
          NavigationLink {
            AgreementDetailView(type: .termsOfService)
          } label: {
            AgreementItemView(
              title: "Terms of Service",
              status: .accepted,
              lastUpdated: Date().addingTimeInterval(-86400 * 30)  // 30 days ago
            )
          }

          NavigationLink {
            AgreementDetailView(type: .privacyPolicy)
          } label: {
            AgreementItemView(
              title: "Privacy Policy",
              status: .pending,
              lastUpdated: Date().addingTimeInterval(-86400 * 7)  // 7 days ago
            )
          }

          NavigationLink {
            AgreementDetailView(type: .dataProcessing)
          } label: {
            AgreementItemView(
              title: "Data Processing Agreement",
              status: .accepted,
              lastUpdated: Date().addingTimeInterval(-86400 * 60)  // 60 days ago
            )
          }

        } header: {
          Text("Agreements")
        }

        // Account & Team Access Section
        Section {
          NavigationLink {
            AccountProfileView()
          } label: {
            HStack {
              Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

              VStack(alignment: .leading) {
                Text("Account Profile")
                  .font(.headline)
                Text("Personal information and preferences")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              Spacer()
            }
          }

          NavigationLink {
            TeamManagementView()
          } label: {
            HStack {
              Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

              VStack(alignment: .leading) {
                Text("Team Management")
                  .font(.headline)
                Text("Manage team settings and members")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              Spacer()
            }
          }

        } header: {
          Text("Account & Teams")
        }
      }
      .navigationTitle("Actions")
      #if !os(macOS)
        .navigationBarTitleDisplayMode(.large)
      #endif
      .toolbar {
        if let onRecordTapped = onRecordTapped {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              onRecordTapped()
            } label: {
              Image(systemName: "camera.fill")
                .font(.system(size: 20))
            }
            .accessibilityLabel("Record")
          }
        }
      }
    }
    .sheet(isPresented: $showingAccountEdit) {
      AccountEditView()
    }
    .sheet(isPresented: $showingTeamManagement) {
      TeamManagementView()
    }
  }
}

// MARK: - Supporting Views

struct ActionItemView: View {
  let icon: String
  let title: String
  let subtitle: String
  let priority: ActionPriority
  let showChevron: Bool

  init(
    icon: String, title: String, subtitle: String, priority: ActionPriority,
    showChevron: Bool = true
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.priority = priority
    self.showChevron = showChevron
  }

  var body: some View {
    HStack {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(priority.color)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      if priority == .urgent {
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundColor(.red)
          .font(.caption)
      }

      if showChevron {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 2)
  }
}

struct AgreementItemView: View {
  let title: String
  let status: AgreementStatus
  let lastUpdated: Date

  var body: some View {
    HStack {
      Image(systemName: status.icon)
        .font(.title2)
        .foregroundColor(status.color)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        Text("Updated \(lastUpdated, style: .relative)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Text(status.displayName)
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .clipShape(Capsule())
    }
    .padding(.vertical, 2)
  }
}

// MARK: - Supporting Types

enum ActionPriority {
  case normal
  case high
  case urgent

  var color: Color {
    switch self {
    case .normal: return .accentColor
    case .high: return .orange
    case .urgent: return .red
    }
  }
}

enum AgreementStatus {
  case accepted
  case pending
  case expired

  var displayName: String {
    switch self {
    case .accepted: return "Accepted"
    case .pending: return "Pending"
    case .expired: return "Expired"
    }
  }

  var icon: String {
    switch self {
    case .accepted: return "checkmark.circle.fill"
    case .pending: return "clock.circle.fill"
    case .expired: return "exclamationmark.triangle.fill"
    }
  }

  var color: Color {
    switch self {
    case .accepted: return .green
    case .pending: return .orange
    case .expired: return .red
    }
  }
}

enum AgreementType {
  case termsOfService
  case privacyPolicy
  case dataProcessing
}

// MARK: - Placeholder Views

struct AgreementDetailView: View {
  let type: AgreementType

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Agreement Details")
          .font(.title)

        Text("This is a placeholder for the \(type) agreement content.")
          .font(.body)

        Spacer()
      }
      .padding()
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var title: String {
    switch type {
    case .termsOfService: return "Terms of Service"
    case .privacyPolicy: return "Privacy Policy"
    case .dataProcessing: return "Data Processing"
    }
  }
}

struct AccountProfileView: View {
  var body: some View {
    Text("Account Profile")
      .navigationTitle("Profile")
  }
}

struct AccountEditView: View {
  var body: some View {
    NavigationStack {
      Text("Edit Account")
        .navigationTitle("Edit Account")
        .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct TeamManagementView: View {
  var body: some View {
    Text("Team Management")
      .navigationTitle("Teams")
  }
}

// MARK: - Preview

#if DEBUG
  struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
      ActionsView(
        captureService: CaptureService(),
        designSystem: .light
      )
      .previewDisplayName("Actions View")
    }
  }
#endif
