//  AppPreferences.swift
//  klu macos assistant
//  Created by Stephen M. Walker II on 3/14/24.
//
//
// Description:
// This view presents a configurable interface for managing core application preferences.
// It allows users to adjust settings such as launching at login, visibility in the menu bar and dock,
// auto-checking for updates, use of global shortcuts, and window behavior between sessions.
// The design employs a clean SwiftUI layout that integrates interactive elements and informative text to guide users.
//
// Key Features:
// - Leverages SwiftUI's @AppStorage for persistent, real-time preference management.
// - Features a dynamic gear-shaped icon with an animated bounce effect on supported macOS versions.
// - Organizes settings into an intuitive Form with toggle rows for clear accessibility.
// - Seamlessly integrates into both onboarding flows and the main Preferences window for consistent configuration.
//
// Section Types:
// - Header Section: Displays a prominent icon and title that introduce the preferences interface.
// - Informational Section: Provides a brief description and usage instructions for the settings.
// - Configuration Section: Contains a Form with organized sections and rows to toggle individual settings.
//
// Notes:
// - User preferences are stored automatically via the AppStorage property wrapper, ensuring they persist across app launches.
// - The component is designed to be adaptable, fitting smoothly into various parts of the app, including initial onboarding and later adjustments via the Preferences menu.
//
// Dependencies:
// - SwiftUI: Utilized for building the user interface and managing state with @AppStorage.
// - macOS 15.0 or later: Required for certain visual effects like the animated bounce effect.
//
// Usage:
// - Integrate AppPreferences into your Preferences view to allow users to customize fundamental app behaviors.
// - Deploy as part of the onboarding process to educate new users on adjusting app settings from the start.

import SwiftUI
import KeyboardShortcuts

/// The basic preferences step of the onboarding process.
struct AppPreferences: View {
    // MARK: - State Properties
    @AppStorage("launchAtLogin") private var launchAtLogin = false {
        didSet {
            // Update the actual login item when the toggle changes
            LaunchAtLoginManager.shared.setLaunchAtLogin(launchAtLogin)
        }
    }
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("showInDock") private var showInDock = true {
        didSet {
            // Call setDockIconVisibility to change the dock visibility
            DockVisibilityManager.shared.setDockIconVisibility(showInDock)
            
            // When turning ON the dock icon, add an extra check after a delay
            // to ensure the change takes effect
            if showInDock {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Double-check that the dock visibility is correct
                    if !DockVisibilityManager.shared.isDockIconVisible() {
                        DockVisibilityManager.shared.setDockIconVisibility(true)
                    }
                }
            }
        }
    }
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @AppStorage("useGlobalShortcut") private var useGlobalShortcut = true
    @AppStorage("alwaysOnTop") private var alwaysOnTop = false
    @AppStorage("rememberWindowPosition") private var rememberWindowPosition = true
    @AppStorage("defaultWindowSize") private var defaultWindowSize = "Medium"
    @AppStorage("newThreadOnLoad") private var newThreadOnLoad = true
    
    private let windowSizes = ["Small", "Medium", "Large", "Custom"]
    
    // MARK: - Initialization
    init() {
        // Sync the AppStorage value with the actual login item status
        launchAtLogin = LaunchAtLoginManager.shared.isEnabled()
        
        // Sync the AppStorage value with the actual dock visibility status
        showInDock = DockVisibilityManager.shared.isDockIconVisible()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundStyle(.primary)
            
            Text("Basic Preferences")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Configure your app behavior, change anytime in Preferences.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
            
            Form {
                Section("Application") {
                    PreferenceToggleRow(
                        title: "Launch at login",
                        description: "Automatically start Klu when you log into your Mac",
                        isOn: $launchAtLogin
                    )
                    
                    PreferenceToggleRow(
                        title: "New thread on app load",
                        description: "Start with a new chat thread each time you open Klu",
                        isOn: $newThreadOnLoad
                    )
                    
                    PreferenceToggleRow(
                        title: "Show in menu bar",
                        description: "Display Klu in the menu bar for quick access",
                        isOn: $showInMenuBar
                    )

                    PreferenceToggleRow(
                        title: "Keep window always on top",
                        description: "Keep the Klu window visible above other windows",
                        isOn: $alwaysOnTop
                    )
                    
                    // PreferenceToggleRow(
                    //     title: "Show in Dock",
                    //     description: "Show Klu icon in the Dock",
                    //     isOn: $showInDock
                    // )
                    
                    // PreferenceToggleRow(
                    //     title: "Automatic updates",
                    //     description: "Keep Klu up to date automatically",
                    //     isOn: $autoCheckForUpdates
                    // )
                }
                
                Section("Keyboard Shortcut") {
                    PreferenceToggleRow(
                        title: "Enable global shortcut",
                        description: "Use a keyboard shortcut to quickly access Klu from anywhere",
                        isOn: $useGlobalShortcut
                    )
                    
                    if useGlobalShortcut {
                        VStack(alignment: .leading) {
                            KeyboardShortcuts.Recorder("Record Shortcut", name: .openAssistant)
                                
                            Text("Press a key combination to set as your global shortcut")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                        }
                    }
                }
                
   
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: 300)
        }
        .padding()
    }
}

// MARK: - Supporting Views

/// A reusable row component for preference toggles
private struct PreferenceToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(title, isOn: $isOn)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview Provider
struct AppPreferences_Previews: PreviewProvider {
    static var previews: some View {
        AppPreferences()
            .frame(width: 600, height: 500)
    }
} 
