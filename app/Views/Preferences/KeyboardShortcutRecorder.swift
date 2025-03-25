//
//  KeyboardShortcutRecorder.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/26/25.
//
//  Description:
//  This component provides a SwiftUI view that allows users to record keyboard shortcuts.
//  It leverages AppKit's NSEvent to monitor key events and update the shortcut string
//  accordingly. The view is represented by an NSTextField that displays the current shortcut.
//
//  Key features:
//  - Records keyboard shortcuts using NSEvent
//  - Displays the shortcut in a text field
//  - Supports special keys and modifier flags
//
//  Implementation details:
//  - NSViewRepresentable bridge
//  - Local event monitoring
//  - Shortcut string construction
//
//  Usage:
//  - Bind the shortcutString to capture and display shortcuts
//  - Integrate into SwiftUI views for custom shortcut recording

import SwiftUI
import AppKit

struct KeyboardShortcutRecorder: NSViewRepresentable {
    @Binding var shortcutString: String
    
    class Coordinator: NSObject {
        var parent: KeyboardShortcutRecorder
        var eventMonitor: Any?
        var textField: NSTextField?
        var pressedKeys: [UInt16: String] = [:] // Track pressed keys by keyCode
        
        init(_ parent: KeyboardShortcutRecorder) {
            self.parent = parent
        }
        
        func startRecording() {
            stopRecording() // Remove existing monitor
            pressedKeys.removeAll() // Clear pressed keys
            
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { event in
                if event.type == .keyDown {
                    let keyCode = event.keyCode
                    if !self.pressedKeys.keys.contains(keyCode) {
                        var keyString: String?
                        if let specialKey = event.specialKey {
                            switch specialKey {
                            case .carriageReturn: keyString = "↩"
                            case .tab: keyString = "⇥"
                            case .delete: keyString = "⌫"
                            case .leftArrow: keyString = "←"
                            case .rightArrow: keyString = "→"
                            case .downArrow: keyString = "↓"
                            case .upArrow: keyString = "↑"
                            default: break
                            }
                        } else {
                            if keyCode == 0x31 {
                                keyString = "Space"
                            } else if (122...126).contains(keyCode) {
                                let fnNumber = keyCode - 122 + 1
                                keyString = "F\(fnNumber)"
                            } else if (96...111).contains(keyCode) {
                                let fnNumber = keyCode - 96 + 5
                                keyString = "F\(fnNumber)"
                            } else if let key = event.charactersIgnoringModifiers {
                                if !key.isEmpty {
                                    keyString = key.uppercased()
                                }
                            }
                        }
                        if let keyString = keyString {
                            self.pressedKeys[keyCode] = keyString
                            self.updateShortcutString(with: event)
                        }
                    }
                    return nil // Consume keyDown event
                } else if event.type == .keyUp {
                    let keyCode = event.keyCode
                    self.pressedKeys.removeValue(forKey: keyCode)
                    if self.pressedKeys.isEmpty {
                        if let textField = self.textField {
                            textField.window?.endEditing(for: textField)
                        }
                    } else {
                        self.updateShortcutString(with: event)
                    }
                    return nil // Consume keyUp event
                } else if event.type == .flagsChanged {
                    self.updateShortcutString(with: event)
                    return event // Don't consume flagsChanged
                }
                return event
            }
        }
        
        func stopRecording() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        
        func updateShortcutString(with event: NSEvent) {
            var components: [String] = []
            
            // Add modifier flags
            if event.modifierFlags.contains(.command) { components.append("⌘") }
            if event.modifierFlags.contains(.option) { components.append("⌥") }
            if event.modifierFlags.contains(.control) { components.append("⌃") }
            if event.modifierFlags.contains(.shift) { components.append("⇧") }
            
            // Add pressed main keys
            for keyString in pressedKeys.values {
                components.append(keyString)
            }
            
            let newShortcut = components.joined(separator: " ")
            self.parent.shortcutString = newShortcut
            self.textField?.stringValue = newShortcut // Update text field immediately
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = true
        textField.isBordered = true
        textField.isEnabled = true
        textField.stringValue = shortcutString
        textField.placeholderString = "Click to record shortcut"
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        
        textField.focusRingType = .exterior
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = shortcutString
    }
}

extension KeyboardShortcutRecorder.Coordinator: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ notification: Notification) {
        startRecording()
    }
    
    func controlTextDidEndEditing(_ notification: Notification) {
        stopRecording()
    }
}
