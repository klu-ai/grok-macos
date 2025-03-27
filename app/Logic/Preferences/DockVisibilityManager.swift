//
//  DockVisibilityManager.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/26/25.
//
//  Description:
//  Manages the application's dock icon visibility using NSApplication.
//  This component provides functionality to show or hide the app's dock icon.
//
//  Key features:
//  - Toggle dock icon visibility
//  - Check current dock icon status
//  - Handle system-level dock integration
//  - Manage window visibility and focus gracefully
//
//  Implementation notes:
//  - Uses AppKit framework
//  - Provides singleton access
//  - Thread-safe operations via DispatchQueue.main.async
//  - Handles main window and settings window ordering based on context
//
//  Usage:
//  - Toggle dock icon via shared instance: DockVisibilityManager.shared.setDockIconVisibility(true/false)
//  - Check current visibility status: DockVisibilityManager.shared.isDockIconVisible()
//  - Manage dock icon presentation and window focus

import AppKit

/// Manages the application's dock icon visibility
class DockVisibilityManager {
    /// Shared instance for singleton access
    static let shared = DockVisibilityManager()
    
    private init() {}
    
    /// Sets whether the application's dock icon should be visible
    /// - Parameter show: Boolean indicating if the dock icon should be shown
    func setDockIconVisibility(_ show: Bool) {
        DispatchQueue.main.async {
            // Capture the current key window to determine if the toggle came from the settings window
            let currentKeyWindow = NSApp.keyWindow
            
            // Check if the settings window is currently key (assumes title contains "Preferences")
            let isSettingsKey = currentKeyWindow?.title.contains("Preferences") ?? false
            
            // Store current window levels to restore them later
            let windows = NSApp.windows
            var windowLevels: [NSWindow: NSWindow.Level] = [:]
            for window in windows {
                windowLevels[window] = window.level
            }
            
            if show {
                // Show the dock icon
                NSApp.setActivationPolicy(.regular)
                
                // Find the main window (assumes title is "Grok Assistant")
                if let mainWindow = windows.first(where: { $0.title == "Grok Assistant" }) {
                    // Restore the main window and bring it to the front
                    mainWindow.setIsVisible(true)
                    mainWindow.orderFrontRegardless()
                    
                    // If the settings window is not key, make the main window the key window
                    if !isSettingsKey {
                        mainWindow.makeKeyAndOrderFront(nil)
                    }
                }
                
                // If the settings window was key, keep it on top
                if isSettingsKey, let settingsWindow = currentKeyWindow {
                    settingsWindow.orderFrontRegardless()
                    settingsWindow.makeKey()
                } else {
                    // Otherwise, activate the app with the main window in focus
                    NSApp.activate(ignoringOtherApps: true)
                }
                
                // Restore original window levels
                self.restoreWindowLevels(windows: windowLevels)
            } else {
                // Hide the dock icon
                NSApp.setActivationPolicy(.accessory)
                
                // Find the main window and ensure it is restored
                if let mainWindow = windows.first(where: { $0.title == "Grok Assistant" }) {
                    mainWindow.setIsVisible(true)
                    mainWindow.orderFrontRegardless()
                }
                
                // If the settings window was key, keep it on top
                if isSettingsKey, let settingsWindow = currentKeyWindow {
                    settingsWindow.orderFrontRegardless()
                    settingsWindow.makeKey()
                } else {
                    // Otherwise, make the main window key and activate the app
                    if let mainWindow = windows.first(where: { $0.title == "Grok Assistant" }) {
                        mainWindow.makeKeyAndOrderFront(nil)
                    }
                    NSApp.activate(ignoringOtherApps: true)
                }
                
                // Restore original window levels
                self.restoreWindowLevels(windows: windowLevels)
            }
        }
    }
    
    /// Helper method to restore original window levels
    private func restoreWindowLevels(windows: [NSWindow: NSWindow.Level]) {
        for (window, level) in windows {
            window.level = level
        }
    }
    
    /// Checks if the application's dock icon is currently visible
    /// - Returns: Boolean indicating if the dock icon is visible
    func isDockIconVisible() -> Bool {
        return NSApp.activationPolicy() == .regular
    }
    

}