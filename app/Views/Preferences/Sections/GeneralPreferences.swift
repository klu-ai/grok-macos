//
//  GeneralPreferences.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages core application behavior and appearance settings. This view provides
//  controls for basic application configuration and system integration options.
//
//  Key features:
//  - Launch behavior configuration
//  - System integration options
//  - Application visibility settings
//
//  Settings categories:
//  - Startup: Launch at login
//  - Visibility: Menu bar and Dock presence
//  - System integration: OS-level integration
//
//  Implementation notes:
//  - Uses AppStorage for persistent settings
//  - Implements standard macOS toggles
//  - Provides descriptive help text
//  - Follows macOS HIG guidelines
//
//  Dependencies:
//  - SwiftUI for interface
//  - AppStorage for persistence
//  - System services integration
//
//  Usage:
//  - Configure app launch behavior
//  - Manage app visibility
//  - Set system integration options

import SwiftUI
import KeyboardShortcuts

/// View containing general application preferences.
struct GeneralPreferences: View {
    @EnvironmentObject var appSettings: AppSettings
    
    // MARK: - State Properties
    @AppStorage("newThreadOnLoad") private var newThreadOnLoad = true
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("showInDock") private var showInDock = true {
        didSet {
            if showInDock != oldValue {
                DockVisibilityManager.shared.setDockIconVisibility(showInDock)
            }
        }
    }
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("useGlobalShortcut") private var useGlobalShortcut = true

    
    // MARK: - Initialization
    init() {
        // Sync the AppStorage value with the actual dock visibility status
        showInDock = DockVisibilityManager.shared.isDockIconVisible()
    }
    
    var body: some View {
        Form {
            Section() {
                Section("Application") {
                    VStack(alignment: .leading) {
                        Toggle("New thread on app load", isOn: $newThreadOnLoad)
                        Text("Start with a new chat thread each time you open Grok")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Show in Menu Bar", isOn: Binding(
                            get: { showInMenuBar },
                            set: { newValue in
                                DispatchQueue.main.async {
                                    showInMenuBar = newValue
                                }
                            }
                        ))
                        .disabled(!showInDock)
                        Text("Display Grok in the menu bar for quick access")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Show in Dock", isOn: Binding(
                            get: { showInDock },
                            set: { newValue in
                                if showInMenuBar {
                                    showInDock = newValue
                                } else {
                                    showInDock = true
                                }
                            }
                        ))
                        .disabled(!showInMenuBar)
                        Text("Show Grok in the Dock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                Section("Keyboard Shortcuts") {
                    VStack(alignment: .leading) {
                        Toggle("Enable global shortcut", isOn: $useGlobalShortcut)
                        Text("Use a keyboard shortcut to quickly access Grok from anywhere")
                                .foregroundColor(.secondary)
                                .font(.caption)
                    }
                    if useGlobalShortcut {
                        KeyboardShortcuts.Recorder("Record Shortcut", name: .openAssistant)
                    }
                }
                Section("Appearance") {
                    VStack(alignment: .leading) {
                        Picker("Theme", selection: $appSettings.appTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        Text("Choose the appearance theme for Grok")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Keep window always on top", isOn: $alwaysOnTop)
                        Text("Keep the Grok window visible above other windows")
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
struct GeneralPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralPreferences()
    }
} 