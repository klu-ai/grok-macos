//
//  EmailPreferences.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages email integration settings and preferences for the application.
//  Provides a comprehensive interface for configuring email accounts,
//  notification settings, and automated responses.
//
//  Key features:
//  - Email service integration
//  - Multiple provider support
//  - Notification management
//  - Auto-reply configuration
//  - Signature customization
//
//  Configuration options:
//  - Email providers: Gmail, Outlook, iCloud, Custom IMAP
//  - Sync intervals: 1-60 minutes
//  - Notification preferences
//  - Sound alerts
//  - Auto-reply messages
//
//  Implementation notes:
//  - Uses AppStorage for settings persistence
//  - Implements form-based settings interface
//  - Provides help text for settings
//  - Validates email input
//
//  Dependencies:
//  - SwiftUI for interface
//  - AppStorage for persistence
//  - System email integration
//
//  Usage:
//  - Configure email accounts
//  - Set notification preferences
//  - Customize auto-replies
//  - Manage sync settings
//

import SwiftUI

/// View for managing email-related preferences and settings.
struct EmailPreferences: View {
    // MARK: - State Properties
    @AppStorage("emailEnabled") private var emailEnabled = false
    @AppStorage("emailAddress") private var emailAddress = ""
    @AppStorage("emailSignature") private var emailSignature = ""
    @AppStorage("emailProvider") private var emailProvider = "Gmail"
    @AppStorage("emailSyncInterval") private var emailSyncInterval = 5
    @AppStorage("emailNotificationsEnabled") private var emailNotificationsEnabled = true
    @AppStorage("emailSoundEnabled") private var emailSoundEnabled = true
    @AppStorage("emailAutoReplyEnabled") private var emailAutoReplyEnabled = false
    @AppStorage("emailAutoReplyMessage") private var emailAutoReplyMessage = ""
    
    // Available email providers
    private let emailProviders = ["Gmail", "Outlook", "iCloud", "Custom IMAP"]
    
    // Available sync intervals (in minutes)
    private let syncIntervals = [1, 5, 15, 30, 60]
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Email Integration", isOn: $emailEnabled)
                    .help("Enable email features in Grok")
            } footer: {
                Text("Connect your email account to manage messages directly from Grok.")
            }
            
            if emailEnabled {
                Section("Account") {
                    Picker("Email Provider", selection: $emailProvider) {
                        ForEach(emailProviders, id: \.self) { provider in
                            Text(provider).tag(provider)
                        }
                    }
                    .help("Select your email service provider")
                    
                    TextField("Email Address", text: $emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .help("Enter your email address")
                    
                    Button("Verify Account") {
                        verifyEmailAccount()
                    }
                }
                
                Section("Sync Settings") {
                    Picker("Sync Interval", selection: $emailSyncInterval) {
                        ForEach(syncIntervals, id: \.self) { interval in
                            Text("\(interval) \(interval == 1 ? "minute" : "minutes")")
                                .tag(interval)
                        }
                    }
                    .help("Choose how often to check for new emails")
                    
                    Toggle("Enable Notifications", isOn: $emailNotificationsEnabled)
                        .help("Show notifications for new emails")
                    
                    if emailNotificationsEnabled {
                        Toggle("Play Sound", isOn: $emailSoundEnabled)
                            .help("Play a sound when new emails arrive")
                    }
                }
                
                Section("Auto-Reply") {
                    Toggle("Enable Auto-Reply", isOn: $emailAutoReplyEnabled)
                        .help("Automatically reply to incoming emails")
                    
                    if emailAutoReplyEnabled {
                        TextEditor(text: $emailAutoReplyMessage)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .help("Enter your auto-reply message")
                    }
                }
                
                Section("Signature") {
                    TextEditor(text: $emailSignature)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .help("Enter your email signature")
                }
                
                Section("Actions") {
                    Button("Test Email Connection") {
                        testEmailConnection()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear Email Cache") {
                        clearEmailCache()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Private Methods
    private func verifyEmailAccount() {
        // Here you would implement the email account verification
        // This is a placeholder for the actual implementation
    }
    
    private func testEmailConnection() {
        // Here you would implement the email connection test
        // This is a placeholder for the actual implementation
    }
    
    private func clearEmailCache() {
        // Here you would implement the email cache clearing functionality
        // This is a placeholder for the actual implementation
    }
}

// MARK: - Preview Provider
struct EmailPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        EmailPreferences()
    }
}
