//
//  LaunchAtLoginManager.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages the application's launch at login behavior using the ServiceManagement framework.
//  This component provides functionality to add or remove the app from the user's login items.
//
//  Key features:
//  - Toggle launch at login state
//  - Check current launch at login status
//  - Handle system-level login item management
//
//  Implementation notes:
//  - Uses ServiceManagement framework
//  - Provides singleton access
//  - Thread-safe operations
//  - Includes debugging to verify helper app presence
//
//  Usage:
//  - Toggle launch at login via shared instance: LaunchAtLoginManager.shared.setLaunchAtLogin(true)
//  - Check current status: LaunchAtLoginManager.shared.isEnabled()
//  - Manage login item registration
//

import Foundation
import ServiceManagement

/// Manages the application's launch at login behavior
class LaunchAtLoginManager {
    /// Shared instance for singleton access
    static let shared = LaunchAtLoginManager()
    
    /// The bundle identifier of the helper app, not the main app.
    /// This must match the identifier of the login helper embedded in Contents/Library/LoginItems.
    private let loginItemIdentifier = "com.humans.klu.LoginItemHelper"
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Sets whether the application should launch at login
    /// - Parameter enable: Boolean indicating if launch at login should be enabled
    /// - Returns: Boolean indicating success or failure
    @discardableResult
    func setLaunchAtLogin(_ enable: Bool) -> Bool {
        // Debugging: Check the contents of Contents/Library/LoginItems
        let loginItemsPath = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LoginItems")
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: loginItemsPath, includingPropertiesForKeys: nil)
            print("Login items directory contents: \(contents)")
            for item in contents {
                if let bundle = Bundle(url: item), let identifier = bundle.bundleIdentifier {
                    print("Found bundle with identifier: \(identifier)")
                }
            }
        } catch {
            print("Error listing login items directory: \(error.localizedDescription)")
        }
        
        // Create a reference to the login item using SMAppService
        let loginItem = SMAppService.loginItem(identifier: loginItemIdentifier)
        
        // Log the current status of the login item for debugging
        print("Current status of login item '\(loginItemIdentifier)': \(loginItem.status)")
        
        // Check if the login item is not found in the bundle
        if loginItem.status == .notFound {
            print("Error: Login item service not found. Verify the helper app is embedded at Contents/Library/LoginItems with identifier '\(loginItemIdentifier)'.")
            return false
        }
        
        // Attempt to enable or disable the login item
        do {
            if enable {
                if loginItem.status == .enabled {
                    print("Login item is already enabled.")
                    return true // Already enabled, no action needed
                }
                print("Attempting to register login item...")
                try loginItem.register()
                print("Successfully registered login item.")
            } else {
                if loginItem.status == .notRegistered {
                    print("Login item is already unregistered.")
                    return true // Already disabled, no action needed
                }
                print("Attempting to unregister login item...")
                try loginItem.unregister()
                print("Successfully unregistered login item.")
            }
            return true
        } catch {
            print("Failed to \(enable ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            // Provide additional error details if available
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain), code: \(nsError.code)")
            }
            return false
        }
    }
    
    /// Checks if the application is set to launch at login
    /// - Returns: Boolean indicating if launch at login is enabled
    func isEnabled() -> Bool {
        let loginItem = SMAppService.loginItem(identifier: loginItemIdentifier)
        return loginItem.status == .enabled
    }
}
