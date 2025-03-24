//
//  MessagesPreferences.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages chat interface and message handling preferences for the application.
//  Provides comprehensive controls for message display, history management,
//  text input behavior, and visual customization options.
//
//  Key features:
//  - Message history configuration
//  - Session management
//  - Auto-save functionality
//  - Visual customization
//  - Text input enhancements
//
//  Display options:
//  - Message alignment
//  - Timestamp formatting
//  - Color scheme selection
//  - Typing indicators
//  - Read receipts
//
//  Text features:
//  - Spell checking
//  - Auto-correction
//  - Smart punctuation
//  - Data detection
//  - Input validation
//
//  Implementation notes:
//  - Uses AppStorage for settings persistence
//  - Implements real-time preview
//  - Manages text input behavior
//  - Handles format preferences
//
//  Usage:
//  - Configure message display
//  - Set history preferences
//  - Customize text behavior
//  - Manage visual options

import SwiftUI

/// View for managing message-related preferences and settings.
struct MessagesPreferences: View {
    // MARK: - State Properties
    @AppStorage("messageHistoryDays") private var messageHistoryDays = 30
    @AppStorage("maxMessagesPerSession") private var maxMessagesPerSession = 100
    @AppStorage("autoSaveInterval") private var autoSaveInterval = 5
    @AppStorage("messageAlignment") private var messageAlignment = "Right"
    @AppStorage("timestampFormat") private var timestampFormat = "12-hour"
    @AppStorage("showTypingIndicator") private var showTypingIndicator = true
    @AppStorage("showReadReceipts") private var showReadReceipts = true
    @AppStorage("enableSpellCheck") private var enableSpellCheck = true
    @AppStorage("enableAutoCorrect") private var enableAutoCorrect = true
    @AppStorage("enableSmartQuotes") private var enableSmartQuotes = true
    @AppStorage("enableSmartDashes") private var enableSmartDashes = true
    @AppStorage("enableDataDetectors") private var enableDataDetectors = true
    @AppStorage("messageColorScheme") private var messageColorScheme = "Default"
    
    // Available message alignments
    private let alignments = ["Left", "Right"]
    
    // Available timestamp formats
    private let timestampFormats = ["12-hour", "24-hour"]
    
    // Available color schemes
    private let colorSchemes = ["Default", "Classic", "Modern", "High Contrast"]
    
    var body: some View {
        Form {
            Section("History") {
                Stepper("Message History: \(messageHistoryDays) days", value: $messageHistoryDays, in: 1...365)
                    .help("Number of days to keep message history")
                
                Stepper("Max Messages per Session: \(maxMessagesPerSession)", value: $maxMessagesPerSession, in: 10...1000, step: 10)
                    .help("Maximum number of messages to keep in a session")
                
                Stepper("Auto-save Interval: \(autoSaveInterval) minutes", value: $autoSaveInterval, in: 1...60)
                    .help("How often to automatically save message history")
            }
            
            Section("Appearance") {
                Picker("Message Alignment", selection: $messageAlignment) {
                    ForEach(alignments, id: \.self) { alignment in
                        Text(alignment).tag(alignment)
                    }
                }
                .help("Choose how messages are aligned in the chat")
                
                Picker("Timestamp Format", selection: $timestampFormat) {
                    ForEach(timestampFormats, id: \.self) { format in
                        Text(format).tag(format)
                    }
                }
                .help("Choose how message timestamps are displayed")
                
                Picker("Color Scheme", selection: $messageColorScheme) {
                    ForEach(colorSchemes, id: \.self) { scheme in
                        Text(scheme).tag(scheme)
                    }
                }
                .help("Choose the color scheme for messages")
            }
            
            Section("Behavior") {
                Toggle("Show Typing Indicator", isOn: $showTypingIndicator)
                    .help("Show when the AI is typing a response")
                
                Toggle("Show Read Receipts", isOn: $showReadReceipts)
                    .help("Show when messages have been read")
            }
            
            Section("Text Editing") {
                Toggle("Enable Spell Check", isOn: $enableSpellCheck)
                    .help("Check spelling while typing")
                
                Toggle("Enable Auto-Correct", isOn: $enableAutoCorrect)
                    .help("Automatically correct misspelled words")
                
                Toggle("Enable Smart Quotes", isOn: $enableSmartQuotes)
                    .help("Convert straight quotes to curly quotes")
                
                Toggle("Enable Smart Dashes", isOn: $enableSmartDashes)
                    .help("Convert hyphens to em dashes when appropriate")
                
                Toggle("Enable Data Detectors", isOn: $enableDataDetectors)
                    .help("Detect and link dates, addresses, and other data")
            }
            
            Section("Preview") {
                MessagePreview(
                    alignment: messageAlignment,
                    colorScheme: messageColorScheme,
                    showTimestamp: true,
                    timestampFormat: timestampFormat
                )
            }
            
            Section("Actions") {
                Button("Clear Message History") {
                    clearMessageHistory()
                }
                .frame(maxWidth: .infinity)
                
                Button("Export Messages") {
                    exportMessages()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Private Methods
    private func clearMessageHistory() {
        // Here you would implement the message history clearing functionality
        // This is a placeholder for the actual implementation
    }
    
    private func exportMessages() {
        // Here you would implement the message export functionality
        // This is a placeholder for the actual implementation
    }
}

// MARK: - MessagePreview
/// A preview component showing how messages will appear with current settings.
struct MessagePreview: View {
    let alignment: String
    let colorScheme: String
    let showTimestamp: Bool
    let timestampFormat: String
    
    private var backgroundColor: Color {
        switch colorScheme {
        case "Classic":
            return .blue.opacity(0.1)
        case "Modern":
            return .purple.opacity(0.1)
        case "High Contrast":
            return .black.opacity(0.1)
        default:
            return .accentColor.opacity(0.1)
        }
    }
    
    private var timestamp: String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = timestampFormat == "12-hour" ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: alignment == "Left" ? .leading : .trailing) {
            VStack(alignment: .leading, spacing: 4) {
                if showTimestamp {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text("Sample message preview")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, alignment: alignment == "Left" ? .leading : .trailing)
        .padding(.vertical)
    }
}

// MARK: - Preview Provider
struct MessagesPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesPreferences()
    }
} 
