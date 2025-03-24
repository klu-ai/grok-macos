//  PreferenceSection.swift
// Grok macOS assistant
//  Created by Stephen M. Walker II on 2/12/25.

//
//  Description:
//  This file defines the PreferenceSection enum, which encapsulates all available sections in the application's Preferences window.
//  It provides a structured, type-safe approach for categorizing settings and driving navigation within the preferences UI.
//
//  Key Features:
//  - Centralizes the definition of preference categories using an enum.
//  - Conforms to CaseIterable and Identifiable for seamless integration with SwiftUI lists.
//  - Utilizes computed properties to logically group sections and to retrieve the corresponding SF Symbol icons.
//  - Supports scalable configuration management and potential future localization.
//
//  Section Types:
//  - General Settings: Core application configurations including global options and permission settings.
//  - AI Features: Options related to models, hardware, and network connections enhancing AI capabilities.
//  - Integrations: Settings for external services such as email, calendar, messaging, and browsing.
//
//  Implementation Notes:
//  - Employs an enum-based design to ensure consistency and type safety across the preference sections.
//  - Computed properties facilitate the organization of sections into groups and the assignment of system icons.
//  - Designed for straightforward extension and maintenance as the application evolves.
//
//  Usage:
//  - Used within the Preferences window to render organized and consistent settings panels.
//  - Facilitates dynamic navigation through different configuration areas by leveraging SwiftUI's list features.
//  - Provides a single source of truth for section metadata, including grouping and iconography.
//
 
import SwiftUI

/// Enum representing the various sections in the Preferences window.
/// Conforms to `CaseIterable` and `Identifiable` to facilitate iteration and unique identification in SwiftUI lists.
enum PreferenceSection: String, CaseIterable, Identifiable {
    case general = "General"
    case permissions = "Permissions"
    case assistant = "Assistant"
    //case notifications = "Notifications"
    // case updates = "Updates"
    case models = "Models"
    case hardware = "Hardware"
    
    
    // TODO: Integration sections temporarily hidden - will be implemented later
    /*
    case connections = "Connections"
    case browsing = "Browsing"
    
    case email = "Email"
    case calendar = "Calendar"
    case messages = "Messages"
    */
    
    /// Unique identifier for each section.
    var id: String { rawValue }
    
    /// Groups the preference sections into logical categories for display.
    /// - Returns: A string representing the group name.
    var group: String {
        switch self {
        case .general, .permissions, .assistant: //, .notifications, .updates
            return "General"
        case .models, .hardware: //.connections
            return "AI"
        // TODO: Integration sections temporarily hidden - will be implemented later
        /*
        case .email, .calendar, .messages, .browsing:
            return "Integrations"
        */
        }
    }
    
    /// Provides the name of the SF Symbol icon associated with each preference section.
    /// - Returns: A string representing the system image name.
    var systemImage: String {
        switch self {
        case .general: return "gear"
        case .permissions: return "lock.shield"
        case .assistant: return "apple.intelligence"
        
        //  this exists, but there are no notification syet
        // case .notifications: return "bell"
        
        // this view exists, but is not yet functional 
        // case .updates: return "arrow.triangle.2.circlepath"
        
        case .models: return "cpu"
        case .hardware: return "memorychip"
        
        // TODO: Integration sections temporarily hidden - will be implemented later
        /*
        case .connections: return "network"
        case .email: return "envelope"
        case .calendar: return "calendar"
        case .messages: return "message"
        case .browsing: return "safari"
        */
        }
    }
    
    /// Returns the appropriate view for each preference section.
    /// - Parameters:
    ///   - runLLM: The RunLLM environment object for AI model management
    ///   - permissionManager: The PermissionManager environment object for handling permissions
    /// - Returns: A view representing the section's content
    @ViewBuilder
    func view(runLLM: RunLLM? = nil, permissionManager: PermissionManager? = nil) -> some View {
        switch self {
        case .general:
            GeneralPreferences()
        case .permissions:
            if let pm = permissionManager {
                PermissionsPreferences()
                    .environmentObject(pm)
            } else {
                PermissionsPreferences()
            }
        case .assistant:
            AssistantPreferences()
        // case .notifications:
            // NotificationsPreferences()
        // case .updates:
            // UpdatesPreferences()
        case .models:
            if let llm = runLLM {
                ModelsPreferences()
                    .environmentObject(llm)
            } else {
                ModelsPreferences()
            }
        case .hardware:
            HardwarePreferences()
        }
    }
} 
