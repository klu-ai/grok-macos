// SetupPermissions.swift
//  klu macos assistant
//  Created by Stephen M. Walker II on 3/14/24.
//
//  Description:
//  This file defines the permissions setup step of the onboarding process for the Klu macOS Assistant.
//  It requests and manages the permissions required for the app's functionality and provides
//  a user interface to track permission statuses.
//
//  Core responsibilities:
//  - Display a list of required and optional permissions
//  - Show the status of each permission
//  - Manage the state of permission requests
//
//  Usage:
//  - This view is presented during the onboarding process to ensure necessary permissions are granted
//  - It uses SwiftUI for layout and design
//  - The PermissionsViewModel handles the logic for requesting permissions
//
//  Dependencies:
//  - SwiftUI for UI components
//  - AVFoundation for camera and microphone access
//  - CoreLocation for location services
//  - EventKit for calendar access
//  - Contacts for contacts access
//  - UserNotifications for notification access

import SwiftUI
import AVFoundation
import CoreLocation
import EventKit
import Contacts
import UserNotifications

/// The permissions step of the onboarding process.
struct SetupPermissions: View {
    @EnvironmentObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(.primary)
            
            Text("System Permissions")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Grant permissions for full functionality.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
            
            Form {
                Section("Required Permissions") {
                    PermissionFormRow(
                        title: "Calendar Access",
                        description: "Needed for scheduling and reminders",
                        status: permissionManager.calendarStatus,
                        action: { permissionManager.requestCalendarAccess() }
                    )
                    
                    PermissionFormRow(
                        title: "Contacts Access",
                        description: "Needed to reference contacts by name",
                        status: permissionManager.contactsStatus,
                        action: { permissionManager.requestContactsAccess() }
                    )
                    
                    PermissionFormRow(
                        title: "Full Disk Access",
                        description: "Allows searching and opening files across your entire drive. You may need to restart the app after granting access.",
                        status: permissionManager.fullDiskAccessStatus,
                        action: { permissionManager.requestFullDiskAccess() }
                    )
                    
                    PermissionFormRow(
                        title: "Location Services",
                        description: "Provides location-based context",
                        status: permissionManager.locationStatus,
                        action: { permissionManager.requestLocationAccess() }
                    )
                    
                    PermissionFormRow(
                        title: "Notifications",
                        description: "Receive real-time alerts from Klu",
                        status: permissionManager.notificationsStatus,
                        action: { permissionManager.requestNotificationsAccess() }
                    )
                }
                
                Section("Optional Permissions") {
                    PermissionFormRow(
                        title: "Camera Access",
                        description: "Enables visual AI features",
                        status: permissionManager.cameraStatus,
                        action: { permissionManager.requestCameraAccess() }
                    )
                    
                    PermissionFormRow(
                        title: "Microphone Access",
                        description: "Enables voice-based AI features",
                        status: permissionManager.microphoneStatus,
                        action: { permissionManager.requestMicrophoneAccess() }
                    )
                    
                    PermissionFormRow(
                        title: "Siri Integration",
                        description: "Enhances voice commands via Siri",
                        status: permissionManager.siriStatus,
                        action: { permissionManager.requestSiriAccess() }
                    )
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: 300)
        }
        .padding()
    }
}

/// A form-styled row for permissions that maintains the same visual structure as PreferenceToggleRow
private struct PermissionFormRow: View {
    let title: String
    let description: String
    let status: PermissionManagerStatus
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                statusView
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .notDetermined:
            Button("Request", action: action)
                .buttonStyle(.borderedProminent)
                //.controlSize(.small)
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
        case .denied:
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference")!)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
    }
}

// MARK: - Preview Provider
struct SetupPermissions_Previews: PreviewProvider {
    static var previews: some View {
        SetupPermissions()
            .frame(width: 600, height: 500)
            .environmentObject(PermissionManager())
    }
}
