//
//  MenuBar.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/23/25.
//
//  Description:
//  This file defines the MenuBarContentView, a SwiftUI view that provides quick access
//  to essential app functionalities directly from the macOS menu bar. It includes options
//  to open the assistant, access settings, and quit the application.
//
//  Core responsibilities:
//  - Displays a button to open the main assistant window
//  - Provides a link to open the application settings
//  - Includes a button to terminate the application
//
//  Usage:
//  - Integrated within the MenuBarExtra to offer quick access to app features
//  - Utilizes WindowManager to manage the main window state
//
//  Dependencies:
//  - SwiftUI for building the user interface
//  - AppKit for application termination functionality
//

import SwiftUI
import AppKit
import SwiftData

@MainActor
/// A SwiftUI view that defines the content of the MenuBarExtra.
/// Provides quick access buttons for opening the assistant, settings, and quitting the app.
struct MenuBarContentView: View {
    /// Reference to the WindowManager to control the main window
    @EnvironmentObject var windowManager: WindowManager
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        Button("Open Assistant") {
            if let win = windowManager.mainWindow {
                windowManager.updateMainWindow(win)
            }
        }
        Divider()
        SettingsLink {
            Text("Open Settings")
        }
        .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}

// MARK: - Preview Provider
struct MenuBarContentView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarContentView()
            .environmentObject(WindowManager.shared)
    }
}