//  WindowManager.swift
//  Grok
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  The WindowManager class is a singleton dedicated to managing the application's main window.
//  It ensures that the window is active, restored from a minimized state if needed, and properly
//  ordered in front of other windows using AppKit functionality.
//
//  Key Features:
//  - Singleton access via WindowManager.shared for centralized window management.
//  - Automatic activation of the application to bring the main window to the forefront.
//  - Restoration of minimized windows through deminiaturization.
//  - Reliable ordering of the window regardless of other active windows.
//
//  Section Types:
//  - Window Management: Handles NSWindow activation, deminiaturization, and ordering operations.
//
//  Implementation Notes:
//  - Implements ObservableObject to allow reactive updates through SwiftUI.
//  - Leverages NSApplication and NSWindow methods to manipulate window state effectively.
//  - Designed for simplicity, serving as the single point of control for the primary application window.
//
//  Usage:
//  - Retrieve the shared instance via WindowManager.shared.
//  - Use updateMainWindow(_:) to manage the target NSWindow, ensuring it is visible and active.
//  - Commonly used by the main app (e.g., in Main.swift) to maintain proper window focus and visibility.

import SwiftUI
import AppKit
import KeyboardShortcuts

/// A singleton class that manages window activation and ordering for the application.
class WindowManager: NSObject, ObservableObject, NSWindowDelegate {
    /// The shared instance for global access.
    static let shared = WindowManager()
    
    /// Published property to hold a reference to the main NSWindow.
    @Published var mainWindow: NSWindow?
    
    /// UserDefaults key for storing sidebar collapsed state
    private let sidebarCollapsedKey = "sidebarCollapsedState"
    
    /// Published property to track sidebar collapsed state
    @Published var isSidebarCollapsed: Bool {
        didSet {
            saveSidebarState()
        }
    }
    
    /// Published property for NavigationSplitViewVisibility
    @Published var sidebarVisibility: NavigationSplitViewVisibility {
        didSet {
            saveSidebarState()
        }
    }
    
    override init() {
        // Initialize sidebar state from UserDefaults
        self.isSidebarCollapsed = UserDefaults.standard.bool(forKey: sidebarCollapsedKey)
        
        // Set sidebar visibility based on the saved state
        self.sidebarVisibility = UserDefaults.standard.bool(forKey: sidebarCollapsedKey) ? 
            .detailOnly : .all
            
        super.init()
        setupShortcutListener()
        
        // Add observer for UserDefaults changes to update window level dynamically
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateWindowLevel()
        }
    }
    
    /// Saves the current sidebar state to UserDefaults
    private func saveSidebarState() {
        UserDefaults.standard.set(isSidebarCollapsed, forKey: sidebarCollapsedKey)
    }
    
    /// Updates the sidebar collapsed state and visibility
    /// - Parameter collapsed: Whether the sidebar is collapsed
    func updateSidebarState(collapsed: Bool) {
        isSidebarCollapsed = collapsed
        sidebarVisibility = collapsed ? .detailOnly : .all
    }
    
    /// Updates the sidebar visibility and collapsed state
    /// - Parameter visibility: The NavigationSplitViewVisibility value
    func updateSidebarVisibility(_ visibility: NavigationSplitViewVisibility) {
        sidebarVisibility = visibility
        isSidebarCollapsed = (visibility == .detailOnly)
    }
    
    /// Updates the window level based on the "alwaysOnTop" setting from UserDefaults
    func updateWindowLevel() {
        guard let window = mainWindow else { return }
        let alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        window.level = alwaysOnTop ? .floating : .normal
    }

    private func setupShortcutListener() {
        KeyboardShortcuts.onKeyUp(for: .openAssistant) { [weak self] in
            guard let self = self else { return }
            if UserDefaults.standard.bool(forKey: "useGlobalShortcut") {
                if let window = self.mainWindow, window.isKeyWindow {
                    window.orderOut(nil)
                } else {
                    self.updateMainWindow(self.mainWindow)
                }
            }
        }
    }
    
    /// Updates the main window reference and ensures that the window is active and visible.
    ///
    /// - Parameter window: The NSWindow instance to be managed.
    func updateMainWindow(_ window: NSWindow?) {
        guard let window = window else { return }
        // If no main window is set yet, assign this window.
        if mainWindow == nil {
            mainWindow = window
            window.delegate = self
        }
        
        // Activate the application, bringing it to the front.
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // If the window is minimized, restore it.
        if window.isMiniaturized { window.deminiaturize(nil) }
        
        // Make sure the window is not hidden
        if !window.isVisible {
            window.setIsVisible(true)
        }
        
        // Bring the window to the front as the key window.
        window.makeKeyAndOrderFront(nil)
        
        // Ensure the window is ordered in front regardless of other windows.
        window.orderFrontRegardless()
        
        // Update window level based on alwaysOnTop preference
        updateWindowLevel()
    }
} 
