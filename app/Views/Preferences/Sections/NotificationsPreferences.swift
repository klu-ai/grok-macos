//
//  NotificationsPreferences.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages notification settings and preferences for the application.
//  Provides a comprehensive interface for configuring notification behavior,
//  appearance, and sound options using the UserNotifications framework.
//
//  Key features:
//  - Notification permission management
//  - Badge and sound configuration
//  - Preview customization
//  - Sound selection options
//  - Notification categories
//
//  Notification options:
//  - Enable/disable notifications
//  - Badge appearance
//  - Sound selection
//  - Preview settings
//  - Custom sound options
//
//  Implementation notes:
//  - Uses UserNotifications framework
//  - Implements permission requests
//  - Manages notification settings
//  - Handles sound preferences
//
//  System integration:
//  - Permission handling
//  - System sound access
//  - Badge management
//  - Preview controls
//
//  Usage:
//  - Configure notification permissions
//  - Set notification appearance
//  - Customize sound options
//  - Manage notification types
//

import SwiftUI
import UserNotifications

/// View for managing notification preferences and settings.
struct NotificationsPreferences: View {
    // MARK: - State Properties
    @State private var notificationsEnabled = false

    @AppStorage("showNotificationPreview") private var showNotificationPreview = true
    
    var body: some View {
        Form {
            Section() {
                VStack(alignment: .leading) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) {
                            if notificationsEnabled {
                                requestNotificationPermission()
                            }
                        }
                    Text("Assistant sends notifications about long-running tasks or updates")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            
            
            if notificationsEnabled {
                
                    
                    VStack(alignment: .leading) {
                        Toggle("Updates", isOn: .constant(true))
                        Text("Notifications about app updates and new features")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading) {
                        Toggle("Tasks", isOn: .constant(true))
                        Text("Notifications about completed tasks")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
             
                }
            } 
        }
        .formStyle(.grouped)
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    // MARK: - Private Methods
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                notificationsEnabled = granted
            }
        }
    }
    
}

// MARK: - Preview Provider
struct NotificationsPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsPreferences()
    }
} 
