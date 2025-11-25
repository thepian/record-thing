import SwiftUI

struct FeatureFlagDebugView: View {
    @ObservedObject var service = FeatureFlagService.shared
    
    var body: some View {
        List {
            Section(header: Text("Local Overrides")) {
                ForEach(FeatureFlag.allCases) { flag in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(flag.label)
                                .font(.headline)
                            Text(flag.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // If overridden, show reset button
                        if service.hasOverride(flag) {
                            Button(action: {
                                service.setOverride(flag, value: nil)
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Toggle("", isOn: Binding(
                            get: { service.isEnabled(flag) },
                            set: { newValue in service.setOverride(flag, value: newValue) }
                        ))
                        .labelsHidden()
                    }
                }
            }
            
            Section(footer: Text("Overrides persist across app launches via UserDefaults.")) {
                EmptyView()
            }
        }
        .navigationTitle("Feature Flags")
    }
}
