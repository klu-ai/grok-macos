//
//  AppDelegate.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 02/12/25.
//
//  Description:
//  Core application delegate that manages the app's lifecycle, permissions, and system integration.
//  This component is responsible for handling application-level events and maintaining global state.
//
//  Key responsibilities:
//  - Manages app lifecycle events (launch, terminate, become active/inactive)
//  - Handles system permission requests and tracking (screen recording, etc.)
//  - Maintains persistent settings via UserDefaults
//  - Coordinates system-level integrations (menu bar, dock, etc.)
//
//  Dependencies:
//  - AppKit: Core macOS UI framework
//  - CoreLocation: Location services integration
//  - EventKit: Calendar and reminder access
//  - Contacts: Address book integration
//  - TipKit: In-app tips and guidance
//
//  Usage notes:
//  - Instantiated automatically by SwiftUI's @NSApplicationDelegateAdaptor
//  - Provides observable properties for app-wide state management
//  - Handles permission requests and persistence
//

import AppKit
import AVFoundation
import os
import TipKit
import CoreLocation      // Framework for location services
import EventKit          // Framework for calendar and reminder access
import Contacts          // Framework for contact access

/// Application delegate responsible for managing the application's lifecycle, system permissions,
/// and persistent settings. This class serves as the central coordinator for app-wide events
/// and state, integrating with macOS system features and SwiftUI's observable architecture.
public class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    // MARK: - Persistent Observable Properties
    // These properties track permission statuses and app activity,
    // and they are automatically synchronized with UserDefaults.
    @Published var hasAllPermissions: Bool = UserDefaults.standard.bool(forKey: "hasAllPermissions") {
        didSet { UserDefaults.standard.set(hasAllPermissions, forKey: "hasAllPermissions") }
    }
    
    @Published var isActive: Bool = UserDefaults.standard.bool(forKey: "isActive") {
        didSet { UserDefaults.standard.set(isActive, forKey: "isActive") }
    }
    
    @Published var hasScreenRecordingPermission: Bool = UserDefaults.standard.bool(forKey: "hasScreenRecordingPermission") {
        didSet { UserDefaults.standard.set(hasScreenRecordingPermission, forKey: "hasScreenRecordingPermission") }
    }
    
    @Published var hasCameraPermission: Bool = UserDefaults.standard.bool(forKey: "hasCameraPermission") {
        didSet { UserDefaults.standard.set(hasCameraPermission, forKey: "hasCameraPermission") }
    }
    
    @Published var hasSiriPermission: Bool = UserDefaults.standard.bool(forKey: "hasSiriPermission") {
        didSet { UserDefaults.standard.set(hasSiriPermission, forKey: "hasSiriPermission") }
    }
    
    @Published var hasFileAccessPermission: Bool = UserDefaults.standard.bool(forKey: "hasFileAccessPermission") {
        didSet { UserDefaults.standard.set(hasFileAccessPermission, forKey: "hasFileAccessPermission") }
    }
    
    @Published var hasLocationPermission: Bool = UserDefaults.standard.bool(forKey: "hasLocationPermission") {
        didSet { UserDefaults.standard.set(hasLocationPermission, forKey: "hasLocationPermission") }
    }
    
    @Published var hasCalendarPermission: Bool = UserDefaults.standard.bool(forKey: "hasCalendarPermission") {
        didSet { UserDefaults.standard.set(hasCalendarPermission, forKey: "hasCalendarPermission") }
    }
    
    @Published var hasContactsPermission: Bool = UserDefaults.standard.bool(forKey: "hasContactsPermission") {
        didSet { UserDefaults.standard.set(hasContactsPermission, forKey: "hasContactsPermission") }
    }
    
    @Published var hasRemindersPermission: Bool = UserDefaults.standard.bool(forKey: "hasRemindersPermission") {
        didSet { UserDefaults.standard.set(hasRemindersPermission, forKey: "hasRemindersPermission") }
    }
    
    // MARK: - Application Lifecycle Methods
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // First, apply dock visibility before doing anything else
        // This should be done early in the launch sequence
        if let showInDock = UserDefaults.standard.object(forKey: "showInDock") as? Bool {
            DockVisibilityManager.shared.setDockIconVisibility(showInDock)
        }
        
        // Initialize app state and start permission checks.
        configureApp()
        checkAndRequestPermissions()
        
        // Asynchronously configure tip features.
        Task {
            try? Tips.configure()
        }
        
        // Bring the application to the foreground.
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    public func applicationDidBecomeActive(_ notification: Notification) {
        // Check the key window's title to determine if it's the main window
        if let keyWindow = NSApp.keyWindow {
            // Only activate if the key window is the main window ("Grok Assistant")
            if keyWindow.title == "Grok Assistant" {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            // If the key window is the settings window (e.g., "Preferences" or untitled), do nothing
        } else {
            // If there's no key window, activate the app (likely the main window will take focus)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    public func applicationDidResignActive(_ notification: Notification) {
        // Update app state when it resigns active status.
        isActive = false
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Return false to keep the app running when no windows are open (typical for menu bar apps).
        return false
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Execute any necessary cleanup prior to termination.
        cleanupBeforeTermination()
    }
    
    // MARK: - Configuration and Cleanup
    
    /// Sets initial state and logs configuration success.
    private func configureApp() {
        isActive = true
        hasAllPermissions = false
        os_log("App configured successfully", type: .info)
    }
    
    /// Performs cleanup operations before the application terminates.
    private func cleanupBeforeTermination() {
        os_log("App is terminating, performing cleanup", type: .info)
    }
    
    // MARK: - Permission Checking Methods
    
    /// Initiates asynchronous checking and requesting of all permissions.
    private func checkAndRequestPermissions() {
        Task {
            await checkScreenRecordingPermission()
            await checkCameraPermission()
            await checkSiriPermission()
            await checkFileAccessPermission()
            await checkLocationPermission()
            await checkCalendarPermission()
            await checkContactsPermission()
            await checkRemindersPermission()
            updatePermissionStatus()
        }
    }
    
    /// Checks and requests screen recording permission.
    private func checkScreenRecordingPermission() async {
        let isAllowed = CGPreflightScreenCaptureAccess()
        // If not already allowed, attempt to request permission.
        hasScreenRecordingPermission = isAllowed || CGRequestScreenCaptureAccess()
    }
    
    /// Checks and requests camera access permission.
    private func checkCameraPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
            
        case .notDetermined:
            hasCameraPermission = await AVCaptureDevice.requestAccess(for: .video)
            
        default:
            hasCameraPermission = false
        }
    }
    
    /// Checks and (if necessary) requests Siri access permission.
    private func checkSiriPermission() async {
        #if os(macOS)
        // On macOS, assume permission for Siri is granted or not applicable.
        hasSiriPermission = true
        #else
        let status = INPreferences.siriAuthorizationStatus()
        if status == .notDetermined {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                INPreferences.requestSiriAuthorization { newStatus in
                    self.hasSiriPermission = (newStatus == .authorized)
                    continuation.resume()
                }
            }
        } else {
            hasSiriPermission = (status == .authorized)
        }
        #endif
    }
    
    /// Verifies file access by checking readability of the Documents directory.
    private func checkFileAccessPermission() async {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
           fileManager.isReadableFile(atPath: documentsURL.path) {
            hasFileAccessPermission = true
        } else {
            hasFileAccessPermission = false
        }
    }
    
    /// Checks location services permission using a custom delegate for asynchronous callback.
    private func checkLocationPermission() async {
        let locationManager = CLLocationManager()
        let delegate = LocationDelegate()
        locationManager.delegate = delegate
        
        let currentStatus = locationManager.authorizationStatus
        if currentStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            let newStatus: CLAuthorizationStatus = await withCheckedContinuation { continuation in
                delegate.continuation = continuation
            }
            hasLocationPermission = (newStatus == .authorized)
        } else {
            hasLocationPermission = (currentStatus == .authorized)
        }
    }
    
    /// Checks and requests calendar access using EventKit.
    private func checkCalendarPermission() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            let eventStore = EKEventStore()
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                eventStore.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            hasCalendarPermission = granted
        } else {
            hasCalendarPermission = (status == .fullAccess)
        }
    }
    
    /// Checks and requests contacts access using the Contacts framework.
    private func checkContactsPermission() async {
        let contactStore = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .notDetermined {
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                print("AppDelegate requesting contacts access at \(Date())")
                contactStore.requestAccess(for: .contacts) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            hasContactsPermission = granted
            if granted {
                restrictToLocalContainers(contactStore: contactStore)
            }
        } else {
            hasContactsPermission = (status == .authorized)
            if hasContactsPermission {
                restrictToLocalContainers(contactStore: contactStore)
            }
        }
    }
    
    private func restrictToLocalContainers(contactStore: CNContactStore) {
        do {
            let predicate = NSPredicate(format: "type == %d", CNContainerType.local.rawValue)
            let localContainers = try contactStore.containers(matching: predicate)
            os_log("AppDelegate restricted contacts to local containers: %@", type: .info, localContainers.map { $0.identifier }.joined(separator: ", "))
        } catch {
            os_log("AppDelegate failed to restrict contacts: %@", type: .error, error.localizedDescription)
        }
    }
    
    /// Checks and requests reminders access using EventKit.
    private func checkRemindersPermission() async {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if status == .notDetermined {
            let eventStore = EKEventStore()
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                eventStore.requestFullAccessToReminders { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            hasRemindersPermission = granted
        } else {
            hasRemindersPermission = (status == .fullAccess)
        }
    }
    
    /// Consolidates individual permission flags into an overall permission status.
    private func updatePermissionStatus() {
        hasAllPermissions = hasScreenRecordingPermission &&
                            hasCameraPermission &&
                            hasSiriPermission &&
                            hasFileAccessPermission &&
                            hasLocationPermission &&
                            hasCalendarPermission &&
                            hasContactsPermission &&
                            hasRemindersPermission
    }
    
    /// Asynchronously configures tip features and logs any configuration errors.
    private func configureTips() async {
        do {
            try Tips.configure()
        } catch {
            os_log("Tips configuration failed: %{public}@", type: .error, error.localizedDescription)
        }
    }
    
    // MARK: - Helper Delegate Class
    
    /// Delegate to manage asynchronous CoreLocation authorization callbacks.
    private class LocationDelegate: NSObject, CLLocationManagerDelegate {
        var continuation: CheckedContinuation<CLAuthorizationStatus, Never>?
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if let cont = continuation {
                cont.resume(returning: status)
                continuation = nil
            }
        }
    }
}
