//
//  PreferencesView.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  This file defines the main preferences interface for the Klu macOS assistant. The preferences system
//  is organized into a hierarchical structure with the following components:
//
//  1. Core Components (in Views/Preferences/):
//     - PreferencesView.swift (this file): Main container using TabView
//     - Models/PreferenceSection.swift: Defines all available preference sections and their grouping
//
//  2. Section Views (in Views/Preferences/Sections/):
//     General Group:
//     - GeneralPreferences.swift: App launch, menu bar, and theme settings
//     - PermissionsPreferences.swift: System permission management
//     - NotificationsPreferences.swift: Notification settings and categories
//     - UpdatesPreferences.swift: Update settings and channels
//
//     AI Group:
//     - ModelsPreferences.swift: AI model selection and configuration
//     - HardwarePreferences.swift: Hardware resource management
//
//  The interface uses a horizontal tab-based navigation. Each tab represents a preference section
//  with its own SF Symbol icon. The content area shows the corresponding settings view for the
//  selected section. Each section view is implemented as a separate SwiftUI view with consistent
//  styling using Form and Section components.
//

import SwiftUI

// MARK: - PreferencesView
/// The main PreferencesView that uses a horizontal tab-based navigation.
/// Each tab represents a preference section with its own icon and content.
struct PreferencesView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var runLLM: RunLLM
    @EnvironmentObject var permissionManager: PermissionManager
    
    /// The currently selected preference section.
    @State private var selection: PreferenceSection = .general
    
    /// Groups the preference sections by category.
    private var groupedSections: [(group: String, sections: [PreferenceSection])] {
        let grouped = Dictionary(grouping: PreferenceSection.allCases, by: { $0.group })
        let desiredOrder = ["General", "AI"]
        return grouped.sorted {
            guard let lhsIndex = desiredOrder.firstIndex(of: $0.key),
                  let rhsIndex = desiredOrder.firstIndex(of: $1.key)
            else { return $0.key < $1.key }
            return lhsIndex < rhsIndex
        }
        .map { (group: $0.key, sections: $0.value) }
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(groupedSections, id: \.group) { group in
                ForEach(group.sections) { section in
                    section.view(runLLM: runLLM, permissionManager: permissionManager)
                        .tabItem {
                            Label(section.rawValue, systemImage: section.systemImage)
                        }
                        .tag(section)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(appSettings.preferredColorScheme)
        // Add spacing between tabs
        .tabViewStyle(.automatic)
        //.padding(8) // Add some padding at the top for better spacing
    }
}

// MARK: - Preview Provider
/// Provides a preview of the PreferencesView for Xcode Canvas.
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(AppSettings(permissionManager: PermissionManager()))
            .environmentObject(RunLLM())
            .environmentObject(PermissionManager())
    }
}
