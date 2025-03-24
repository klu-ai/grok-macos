//
//  PermissionsPreferences.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages system permissions and access controls for the application.
//  Provides a centralized interface for viewing, requesting, and managing
//  various system permissions required for app functionality.
//
//  Key features:
//  - Permission status monitoring
//  - System settings integration
//  - Access request handling
//  - Permission guidance
//
//  Permission types:
//  - Screen Recording: Screen content capture
//  - Calendar Access: Event management
//  - Contacts Access: Address book integration
//  - Reminders Access: Task management
//  - Full Disk Access: Complete file system access
//
//  Implementation notes:
//  - Uses system permission APIs
//  - Implements deep linking to settings
//  - Handles permission state changes
//  - Provides user guidance
//
//  Security considerations:
//  - Permission state verification
//  - Secure access requests
//  - Privacy-focused design
//  - Clear user communication
//
//  Usage:
//  - View permission status
//  - Request system access
//  - Manage permissions
//  - Access system settings
//
import SwiftUI
import EventKit
import Contacts
import ScreenCaptureKit

struct PermissionsPreferences: View {
    // MARK: - State Properties
    @EnvironmentObject var permissionManager: PermissionManager
    
    // MARK: - Environment
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Form {
            Section() {
                // Screen Recording Permission
                PermissionRow(
                    title: "Screen Recording",
                    description: "Required for reviewing screen content",
                    systemImage: "display",
                    isEnabled: permissionManager.screenRecordingEnabled
                ) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        openURL(url)
                    }
                }
                
                // Microphone Permission
                PermissionRow(
                    title: "Microphone",
                    description: "Required for audio input and transcription",
                    systemImage: "mic.fill",
                    isEnabled: permissionManager.microphoneStatus == .granted
                ) {
                    permissionManager.requestMicrophoneAccess()
                }
                
                // Calendar Permission
                PermissionRow(
                    title: "Calendar",
                    description: "Access to view and manage calendar events",
                    systemImage: "calendar",
                    isEnabled: permissionManager.calendarAccessEnabled
                ) {
                    permissionManager.requestCalendarAccess()
                }
                
                // Contacts Permission
                PermissionRow(
                    title: "Contacts",
                    description: "Access to view and manage contacts",
                    systemImage: "person.crop.circle",
                    isEnabled: permissionManager.contactsAccessEnabled
                ) {
                    permissionManager.requestContactsAccess()
                }
                
                // Reminders Permission
                PermissionRow(
                    title: "Reminders",
                    description: "Access to view and manage reminders",
                    systemImage: "list.bullet.rectangle",
                    isEnabled: permissionManager.remindersAccessEnabled
                ) {
                    permissionManager.requestRemindersAccess()
                }
                
                // Full Disk Access Permission
                PermissionRow(
                    title: "Full Disk Access",
                    description: "Allows searching and opening files across your entire drive. You may need to restart the app after granting access.",
                    systemImage: "externaldrive.fill",
                    isEnabled: permissionManager.fullDiskAccessStatus == .granted
                ) {
                    permissionManager.requestFullDiskAccess()
                }
            }
            
            Section {
                VStack(alignment: .leading) {

                    Toggle("Share anonymous feature usage stats", isOn: .constant(false))

                    Divider()
                    
                    Toggle("Share crash reports to improve stability", isOn: .constant(false))
                    
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            permissionManager.checkPermissions()
        }
    }
    

}

// MARK: - PermissionRow Component
struct PermissionRow: View {
    let title: String
    let description: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Button(action: action) {
                    Text(isEnabled ? "Granted" : "Enable")
                }
                .disabled(isEnabled)
            }
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

    }
}

struct PermissionsPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsPreferences()
    }
}