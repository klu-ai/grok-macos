//
//  UpdatesPreferences.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/19/25.
//
//  Description:
//  Manages application update settings and preferences. This view provides
//  controls for configuring how the application handles software updates.
//
//  Key features:
//  - Automatic update checking configuration
//  - Update frequency selection
//  - Update channel selection
//
//  Settings categories:
//  - Update checking: Enable/disable automatic checks
//  - Frequency: How often to check for updates
//  - Channel: Which release channel to use
//
//  Implementation notes:
//  - Uses AppStorage for persistent settings
//  - Implements standard macOS controls
//  - Provides descriptive help text
//  - Follows macOS HIG guidelines

import SwiftUI

/// View containing update preferences and settings.
struct UpdatesPreferences: View {
    // MARK: - State Properties
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    
    var body: some View {
        Form {
            Section() {
                VStack(alignment: .leading) {
                    Toggle("Automatically check for updates", isOn: $autoCheckForUpdates)
                    Text("Periodically check for new versions of Klu")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                if autoCheckForUpdates {
                    

                        VStack(alignment: .leading) {
                            Picker("Update Frequency", selection: .constant("Daily")) {
                                Text("Hourly").tag("Hourly")
                                Text("Daily").tag("Daily") 
                                Text("Weekly").tag("Weekly")
                                Text("Monthly").tag("Monthly")
                            }
                            Text("How often Klu should check for updates")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        VStack(alignment: .leading) {
                            Picker("Update Channel", selection: .constant("Stable")) {
                                Text("Stable").tag("Stable")
                                Text("Beta").tag("Beta")
                                Text("Nightly").tag("Nightly")
                            }
                            Text("Choose which release channel to receive updates from")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            }
                    
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Preview Provider
struct UpdatesPreferences_Previews: PreviewProvider {
    static var previews: some View {
        UpdatesPreferences()
    }
} 