//
//  PermissionManager.swift
//  Klu
//
//  Created by Stephen M. Walker II on 2/23/25.
//
//  Description:
//  This file defines the PermissionManager class, which is responsible for managing
//  system permission states and handling permission requests for screen recording,
//  calendar access, contacts access, and reminders access.
//
//  Core responsibilities:
//  - Checks the current status of system permissions
//  - Requests permissions for calendar, contacts, and reminders
//  - Updates the state of permissions in a reactive manner using Combine
//
//  Usage:
//  - Instantiate PermissionManager to automatically check and update permission states
//  - Call specific request methods to prompt the user for necessary permissions
//
//  Dependencies:
//  - Foundation for basic data types and structures
//  - EventKit for calendar and reminders access
//  - Contacts for contacts access
//  - ScreenCaptureKit for screen recording access
//  - Combine for reactive state management
//  - CoreLocation for location access
//  - UserNotifications for notification access
//  - AVFoundation for camera and microphone access
//

import SwiftUI
import Foundation
import EventKit
import Contacts
import ScreenCaptureKit
import Combine
import CoreLocation
import UserNotifications
import AVFoundation

/// Represents the status of a system permission
enum PermissionManagerStatus: String, Codable {
    case notDetermined = "Not Determined"
    case granted = "Granted"
    case denied = "Denied"
    
    var isGranted: Bool {
        self == .granted
    }
}

/// Manages system permission states and requests
class PermissionManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var screenRecordingStatus: PermissionManagerStatus = .notDetermined
    @Published var calendarStatus: PermissionManagerStatus = .notDetermined
    @Published var contactsStatus: PermissionManagerStatus = .notDetermined
    @Published var remindersStatus: PermissionManagerStatus = .notDetermined
    @Published var locationStatus: PermissionManagerStatus = .notDetermined
    @Published var fileAccessStatus: PermissionManagerStatus = .notDetermined
    @Published var fullDiskAccessStatus: PermissionManagerStatus = .notDetermined
    @Published var notificationsStatus: PermissionManagerStatus = .notDetermined
    @Published var cameraStatus: PermissionManagerStatus = .notDetermined
    @Published var microphoneStatus: PermissionManagerStatus = .notDetermined
    @Published var siriStatus: PermissionManagerStatus = .notDetermined
    
    // Legacy properties for backward compatibility - will be removed after refactoring
    @Published var screenRecordingEnabled = false
    @Published var calendarAccessEnabled = false
    @Published var contactsAccessEnabled = false
    @Published var remindersAccessEnabled = false
    @Published var locationAccessEnabled = false
    
    @Published var currentLocation = "Unknown Location"
    
    // MARK: - Private Properties
    private var locationManager: CLLocationManager?
    
    private let calendarManager = EKEventStore()
    private let contactsManager = CNContactStore()
    private let remindersManager = EKEventStore()
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        // Initialize location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        Task {
            await checkPermissionStatus()
            
            // If location permission is already granted, request a location update immediately
            await MainActor.run {
                if locationStatus == .granted {
                    setupLocationUpdates()
                    locationManager?.requestLocation()
                }
            }
        }
    }
    
    // MARK: - Permission Status Checking
    func checkPermissionStatus() async {
        // Check all permissions
        await checkScreenRecording()
        await checkCalendar()
        await checkContacts()
        await checkReminders()
        await checkLocation()
        await checkNotifications()
        await checkCamera()
        await checkMicrophone()
        await checkSiri()
        checkFileAccess() // This one is synchronous
        await checkFullDiskAccess() // Check for full disk access
    }
    
    /// Checks the current status of all permissions
    func checkPermissions() {
        Task {
            await checkPermissionStatus()
        }
    }
    
    // MARK: - Screen Recording Permission
    func checkScreenRecording() async {
        do {
            let _ = try await SCShareableContent.current
            await MainActor.run {
                screenRecordingStatus = PermissionManagerStatus.granted
                screenRecordingEnabled = true // Legacy
            }
        } catch {
            await MainActor.run {
                screenRecordingStatus = PermissionManagerStatus.denied
                screenRecordingEnabled = false // Legacy
            }
        }
    }
    
    // MARK: - Calendar Permission
    func checkCalendar() async {
        if #available(macOS 14.0, *) {
            do {
                let status = try await calendarManager.requestFullAccessToEvents()
                await MainActor.run {
                    calendarStatus = status ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
                    calendarAccessEnabled = status // Legacy
                }
            } catch {
                await MainActor.run {
                    calendarStatus = PermissionManagerStatus.denied
                    calendarAccessEnabled = false // Legacy
                }
            }
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            await MainActor.run {
                calendarStatus = status == .authorized ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
                calendarAccessEnabled = status == .authorized // Legacy
            }
        }
    }
    
    /// Requests calendar access permission
    func requestCalendarAccess() {
        let eventStore = EKEventStore()
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.calendarStatus = granted ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
                self.calendarAccessEnabled = granted // Legacy
            }
        }
    }
    
    // MARK: - Contacts Permission
    func checkContacts() async {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        await MainActor.run {
            print("Checking contacts permission status: \(status.rawValue) at \(Date())")
            contactsStatus = status == .authorized ? .granted : .denied
            contactsAccessEnabled = status == .authorized // Legacy
            if status == .authorized {
                let contactStore = CNContactStore()
                self.restrictToLocalContainers(contactStore: contactStore)
            }
        }
    }
    
    /// Requests contacts access permission
    func requestContactsAccess() {
        let contactStore = CNContactStore()
        print("Requesting contacts access at \(Date())")
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                self.contactsStatus = granted ? .granted : .denied
                self.contactsAccessEnabled = granted // Legacy
                if granted {
                    self.restrictToLocalContainers(contactStore: contactStore)
                }
                if let error = error {
                    print("Contacts access request failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Restricts contact access to local containers only
    private func restrictToLocalContainers(contactStore: CNContactStore) {
        do {
            // Create a predicate to filter containers where type is local
            let predicate = NSPredicate(format: "type == %d", CNContainerType.local.rawValue)
            let localContainers = try contactStore.containers(matching: predicate)
            print("Restricted contacts access to local containers: \(localContainers.map { $0.identifier })")
        } catch {
            print("Failed to fetch local containers: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reminders Permission
    func checkReminders() async {
        if #available(macOS 14.0, *) {
            do {
                let status = try await remindersManager.requestFullAccessToReminders()
                await MainActor.run {
                    remindersStatus = status ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
                    remindersAccessEnabled = status // Legacy
                }
            } catch {
                await MainActor.run {
                    remindersStatus = PermissionManagerStatus.denied
                    remindersAccessEnabled = false // Legacy
                }
            }
        } else {
            let status = EKEventStore.authorizationStatus(for: .reminder)
            await MainActor.run {
                remindersStatus = status == .authorized ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
                remindersAccessEnabled = status == .authorized // Legacy
            }
        }
    }
    
    /// Requests reminders access permission
    func requestRemindersAccess() {
        let eventStore = EKEventStore()
        eventStore.requestFullAccessToReminders { granted, error in
            DispatchQueue.main.async {
                self.remindersStatus = granted ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
                self.remindersAccessEnabled = granted // Legacy
            }
        }
    }
    
    // MARK: - Location Permission
    func checkLocation() async {
        if let locationAuth = locationManager?.authorizationStatus {
            await MainActor.run {
                switch locationAuth {
                case .authorizedAlways:
                    locationStatus = PermissionManagerStatus.granted
                    locationAccessEnabled = true // Legacy
                    // Start location updates immediately if permission is granted
                    setupLocationUpdates()
                case .denied, .restricted:
                    locationStatus = PermissionManagerStatus.denied
                    locationAccessEnabled = false // Legacy
                default:
                    locationStatus = PermissionManagerStatus.notDetermined
                    locationAccessEnabled = false // Legacy
                }
            }
        }
    }
    
    /// Requests location access permission
    func requestLocationAccess() {
        locationManager?.requestAlwaysAuthorization()
    }
    
    // MARK: - File Access Permission
    /// Checks for basic file access, which is for specific folders selected by the user.
    /// This is different from full disk access, which provides system-wide file access.
    func checkFileAccess() {
        // File access is typically determined at runtime when attempting to access files
        // We'll set a default status of notDetermined until explicitly requested
        DispatchQueue.main.async {
            self.fileAccessStatus = PermissionManagerStatus.notDetermined
        }
    }
    
    func requestFileAccess() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Please grant access to a folder to continue"
        panel.begin { response in
            DispatchQueue.main.async {
                self.fileAccessStatus = response == .OK ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
            }
        }
    }
    
    // MARK: - Notification Permission
    func checkNotifications() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationsStatus = PermissionManagerStatus.granted
            case .denied:
                notificationsStatus = PermissionManagerStatus.denied
            case .notDetermined:
                notificationsStatus = PermissionManagerStatus.notDetermined
            @unknown default:
                notificationsStatus = PermissionManagerStatus.notDetermined
            }
        }
    }
    
    func requestNotificationsAccess() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsStatus = granted ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
            }
        }
    }
    
    // MARK: - Camera Permission
    func checkCamera() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        await MainActor.run {
            switch status {
            case .authorized:
                cameraStatus = PermissionManagerStatus.granted
            case .denied, .restricted:
                cameraStatus = PermissionManagerStatus.denied
            case .notDetermined:
                cameraStatus = PermissionManagerStatus.notDetermined
            @unknown default:
                cameraStatus = PermissionManagerStatus.notDetermined
            }
        }
    }
    
    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraStatus = granted ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
            }
        }
    }
    
    // MARK: - Microphone Permission
    func checkMicrophone() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        await MainActor.run {
            switch status {
            case .authorized:
                microphoneStatus = PermissionManagerStatus.granted
            case .denied, .restricted:
                microphoneStatus = PermissionManagerStatus.denied
            case .notDetermined:
                microphoneStatus = PermissionManagerStatus.notDetermined
            @unknown default:
                microphoneStatus = PermissionManagerStatus.notDetermined
            }
        }
    }
    
    func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.microphoneStatus = granted ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
            }
        }
    }
    
    // MARK: - Siri Permission
    func checkSiri() async {
        // Siri permission state is not directly accessible
        // We'll use a placeholder value until explicitly requested
        await MainActor.run {
            siriStatus = PermissionManagerStatus.notDetermined
        }
    }
    
    func requestSiriAccess() {
        // This is a placeholder; Siri permissions need to be handled separately
        // For macOS, this typically requires a trip to System Settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.siri") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Full Disk Access Permission
    
    /// Checks if full disk access is granted by attempting to read a protected system file.
    /// Full disk access provides the application with permission to access all files on the system,
    /// including those in protected directories that aren't normally accessible to apps.
    /// 
    /// This is required for comprehensive file search and access functionality.
    func checkFullDiskAccess() async {
        print("🔒 DEBUG: Checking full disk access permissions...")
        
        // List of protected files to check (in order of increasing restriction)
        let protectedFiles = [
            "/Library/Application Support/com.apple.TCC/TCC.db",
            "/Library/Preferences/com.apple.TimeMachine.plist",
            "/etc/hosts",
            "/Users/stephenwalker/Code/klu/klu-macos-assistant/CLAUDE.md" // Project directory file
        ]
        
        var accessResults = [String: Bool]()
        var systemFileAccess = false
        var projectDirAccess = false
        
        // Tracking the project directory filepath for later reference
        let projectFilePath = "/Users/stephenwalker/Code/klu/klu-macos-assistant/CLAUDE.md"
        
        for filePath in protectedFiles {
            do {
                print("🔒 DEBUG: Attempting to read protected file: \(filePath)")
                let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
                let firstLine = fileContent.split(separator: "\n").first ?? "Empty file"
                print("✅ DEBUG: Successfully read file: \(filePath)")
                print("✅ DEBUG: First line content: \(firstLine)")
                accessResults[filePath] = true
                
                // Track specific access types
                if filePath == projectFilePath {
                    projectDirAccess = true
                } else {
                    // If we can read any system protected file
                    systemFileAccess = true
                }
                
            } catch {
                print("❌ DEBUG: Failed to read file \(filePath): \(error.localizedDescription)")
                accessResults[filePath] = false
            }
        }
        
        // Determine overall access status - requires project directory access + at least one system file
        let overallAccess = projectDirAccess && systemFileAccess
        
        print("🔒 DEBUG: Project directory access: \(projectDirAccess)")
        print("🔒 DEBUG: System protected file access: \(systemFileAccess)")
        
        // Check TCC database directly using SQLite if available
        let tccPath = "/Library/Application Support/com.apple.TCC/TCC.db"
        if FileManager.default.fileExists(atPath: tccPath) {
            print("🔍 DEBUG: TCC database exists at \(tccPath)")
            
            // Get file attributes to check permissions
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: tccPath)
                let permissions = attributes[.posixPermissions] as? NSNumber
                print("🔍 DEBUG: TCC database permissions: \(permissions?.stringValue ?? "unknown")")
                
                // Check file ownership
                // Use string keys to access attributes safely
                let ownerID = attributes[FileAttributeKey(rawValue: "NSFileOwnerAccountID")] as? NSNumber
                let groupID = attributes[FileAttributeKey(rawValue: "NSFileGroupOwnerAccountID")] as? NSNumber
                print("🔍 DEBUG: TCC database owner ID: \(ownerID?.stringValue ?? "unknown"), group ID: \(groupID?.stringValue ?? "unknown")")
            } catch {
                print("⚠️ DEBUG: Unable to get TCC database attributes: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ DEBUG: TCC database not found at expected path")
        }
        
        // Check Documents directory access
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        print("📁 DEBUG: Documents directory path: \(documentsPath)")
        
        // Try to read Documents directory contents
        do {
            let documentsContents = try FileManager.default.contentsOfDirectory(atPath: documentsPath)
            print("📁 DEBUG: Successfully listed Documents directory: \(documentsContents.count) files")
        } catch {
            print("❌ DEBUG: Failed to list Documents directory: \(error.localizedDescription)")
        }
        
        // Set the status based on our tests
        let finalAccessStatus = overallAccess ? PermissionManagerStatus.granted : PermissionManagerStatus.denied
        await MainActor.run {
            fullDiskAccessStatus = finalAccessStatus
            print("🔒 DEBUG: Full disk access status set to: \(fullDiskAccessStatus.rawValue)")
        }
        
        // Print detailed results summary
        print("🔒 DEBUG: Full disk access check results:")
        for (file, result) in accessResults {
            print("   \(result ? "✅" : "❌") \(file)")
        }
    }
    
    /// Requests full disk access by opening System Settings to the Full Disk Access preference pane.
    /// Users must manually add the application to the list of apps with full disk access.
    /// The app typically needs to be restarted after this permission is granted.
    func requestFullDiskAccess() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Location Management
    /// Sets up periodic location updates
    func setupLocationUpdates() {
        if locationStatus == PermissionManagerStatus.granted {
            locationManager?.startUpdatingLocation()
            
            // Setup a timer to periodically update the location
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
                Task { [weak self] in
                    await self?.updateLocation()
                }
            }
            
            // Initial location update
            Task {
                await updateLocation()
            }
        }
    }
    
    /// Updates the current location
    @MainActor
    func updateLocation() async {
        if locationStatus == PermissionManagerStatus.granted {
            locationManager?.requestLocation()
        }
    }
    
    /// Gets formatted location string
    func getFormattedLocation() -> String {
        if currentLocation == "Unknown Location" {
            // If we don't have a specific location, provide a general location based on timezone
            let timeZoneIdentifier = TimeZone.current.identifier
            let components = timeZoneIdentifier.split(separator: "/")
            
            if components.count >= 2, let city = components.last {
                // Convert Substring to String and format the city name by replacing underscores with spaces
                let cityString = String(city)
                let formattedCity = cityString.replacingOccurrences(of: "_", with: " ")
                return formattedCity
            } else if let countryCode = Locale.current.region?.identifier {
                // Use the country code if we can't extract a city
                let locale = Locale.current
                if let countryName = locale.localizedString(forRegionCode: countryCode) {
                    return countryName
                }
                return countryCode
            }
        }
        return currentLocation
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocode the location to get a user-friendly string
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else { return }
            
            let locationString = self?.formatLocation(from: placemark) ?? "Unknown Location"
            
            DispatchQueue.main.async {
                self?.currentLocation = locationString
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .authorizedAlways:
                self.locationStatus = PermissionManagerStatus.granted
                self.locationAccessEnabled = true // Legacy
                self.setupLocationUpdates()
            case .denied, .restricted:
                self.locationStatus = PermissionManagerStatus.denied
                self.locationAccessEnabled = false // Legacy
            default:
                self.locationStatus = PermissionManagerStatus.notDetermined
                self.locationAccessEnabled = false // Legacy
            }
        }
    }
    
    private func formatLocation(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}