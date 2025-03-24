//
//  WindowAccessor.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Provides a bridge between SwiftUI and AppKit window management.
//  Enables SwiftUI views to access and manipulate the underlying
//  NSWindow, particularly for window capture and text field focus.
//
//  Key features:
//  - Window capture
//  - Focus management
//  - Text field access
//  - Window hierarchy traversal
//
//  Implementation details:
//  - NSViewRepresentable bridge
//  - Recursive view search
//  - Async window capture
//  - First responder handling
//
//  Usage:
//  - Window reference capture
//  - Text field focus
//  - Window activation
//  - View hierarchy access

// This is used to handle the main window of the application.
// It is used to capture the NSWindow and make it the main window.
// It is also used to find the text field in the window hierarchy and make it the first responder.

import SwiftUI
import AppKit

/// A SwiftUI view that embeds an NSView to capture the underlying NSWindow.
/// This allows the SwiftUI view to interact with AppKit's NSWindow API.
/// The NSView is used solely for window reference extraction.
struct WindowAccessor: NSViewRepresentable {
    /// A binding to store the reference to the captured NSWindow.
    @Binding var window: NSWindow?
    
    /// Creates the NSView that will be used to capture the NSWindow.
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        // Dispatch asynchronously to ensure that the NSView is added to the window hierarchy
        // before attempting to capture its window.
        DispatchQueue.main.async {
            self.window = nsView.window  // Capture the NSWindow associated with the NSView.
            self.window?.makeKeyAndOrderFront(nil)  // Bring the window to the front and make it key.
            
            // Add an observer for when the window becomes key (active)
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: self.window,
                queue: .main
            ) { _ in
                // Using a slightly delayed focus to ensure view hierarchy is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Try to find text fields that might match our chat input
                    let textFields = nsView.window?.contentView?.recursiveSubviews.filter { 
                        ($0 is NSTextField) && !($0 is NSSearchField)
                    } as? [NSTextField]
                    
                    // First try to find one with our identifier
                    if let chatField = textFields?.first(where: { $0.accessibilityIdentifier() == "chatInputField" }) {
                        nsView.window?.makeFirstResponder(chatField)
                    } 
                    // Fall back to finding an editable text field that's not a search field
                    else if let editableField = textFields?.first(where: { $0.isEditable }) {
                        nsView.window?.makeFirstResponder(editableField) 
                    }
                }
                
                // Remove the observer after it's fired once
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.didBecomeKeyNotification,
                    object: self.window
                )
            }
        }
        return nsView
    }
    
    /// Updates the NSView; not needed in this case, so left empty.
    func updateNSView(_ nsView: NSView, context: Context) { }
}

// Extension to help find views recursively
private extension NSView {
    var recursiveSubviews: [NSView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}
