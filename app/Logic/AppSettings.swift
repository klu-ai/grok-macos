//
//  Data.swift
//  klu
//
//  Created by Stephen M. Walker II on 2/22/25.
//
//  Overview:
//  This file contains the AppManager class and related enums used in the Klu macOS assistant.
//  It leverages SwiftUI and SwiftData for managing application state and user preferences.
//
//  Core Components:
//  - AppManager: Manages application-wide settings, user preferences, and installed models.
//  - AppTheme: Enum for defining the app's UI theme options (system, light, dark).
//  - AppTintColor: Enum for defining the app's tint color options.
//  - AppFontDesign: Enum for defining the app's font design options.
//  - AppFontWidth: Enum for defining the app's font width options.
//  - AppFontSize: Enum for defining the app's font size options.
//
//  Features:
//  - Persistent storage of user preferences using @AppStorage.
//  - Management of installed models with automatic saving and loading.
//  - Dynamic theme switching with system appearance detection.
//  - Comprehensive font and color customization options.
//
//  Implementation Details:
//  - Utilizes SwiftUI's @AppStorage for storing user preferences.
//  - Uses JSON encoding/decoding for saving and loading installed models.
//  - Provides computed properties for theme-based color scheme detection.
//  - Implements type-safe enums for UI customization options.
//
//  Usage:
//  - Manage and persist user preferences.
//  - Control application appearance through theme, color, and font settings.
//  - Track and manage installed AI models.
//  - Format model names for display.
//

import SwiftUI
import AppKit
import SwiftData

/// Represents the possible UI theme options
enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

/// Manages application-wide settings, user preferences, and installed models.
@MainActor
class AppSettings: ObservableObject {
    // MARK: - Properties
    
    /// The preferred color scheme for the app
    @Published var preferredColorScheme: ColorScheme?
    
    /// Whether to show the dock icon
    @Published var showDockIcon: Bool {
        didSet {
            DockVisibilityManager.shared.setDockIconVisibility(showDockIcon)
        }
    }
    
    /// Whether to start at login
    @Published var startAtLogin: Bool {
        didSet {
            LaunchAtLoginManager.shared.setLaunchAtLogin(startAtLogin)
        }
    }
    
    /// Whether to use global shortcut
    @Published var useGlobalShortcut: Bool {
        didSet {
            UserDefaults.standard.set(useGlobalShortcut, forKey: "useGlobalShortcut")
        }
    }
    
    /// Whether to keep window on top
    @Published var alwaysOnTop: Bool {
        didSet {
            UserDefaults.standard.set(alwaysOnTop, forKey: "alwaysOnTop")
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize properties from UserDefaults
        self.preferredColorScheme = ColorScheme(rawValue: UserDefaults.standard.integer(forKey: "preferredColorScheme"))
        self.showDockIcon = !UserDefaults.standard.bool(forKey: "hideDockIcon")
        self.startAtLogin = UserDefaults.standard.bool(forKey: "startAtLogin")
        self.useGlobalShortcut = UserDefaults.standard.bool(forKey: "useGlobalShortcut")
        self.alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        
        // Set up observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleColorSchemeChange),
            name: NSNotification.Name("ColorSchemeDidChange"),
            object: nil
        )
    }
    
    // MARK: - Methods
    
    /// Sets the preferred color scheme
    func setPreferredColorScheme(_ scheme: ColorScheme?) {
        preferredColorScheme = scheme
        UserDefaults.standard.set(scheme?.rawValue ?? -1, forKey: "preferredColorScheme")
    }
    
    /// Handles color scheme changes
    @objc private func handleColorSchemeChange() {
        // Handle color scheme changes if needed
    }
}

/// Enum for defining the app's tint color options.
enum AppTintColor: String, CaseIterable {
    case monochrome, blue, brown, gray, green, indigo, mint, orange, pink, purple, red, teal, yellow
    
    /// Returns the corresponding Color for each tint color option.
    func getColor() -> Color {
        switch self {
        case .monochrome:
            .primary
        case .blue:
            .blue
        case .red:
            .red
        case .green:
            .green
        case .yellow:
            .yellow
        case .brown:
            .brown
        case .gray:
            .gray
        case .indigo:
            .indigo
        case .mint:
            .mint
        case .orange:
            .orange
        case .pink:
            .pink
        case .purple:
            .purple
        case .teal:
            .teal
        }
    }
}

/// Enum for defining the app's font design options.
enum AppFontDesign: String, CaseIterable {
    case standard, monospaced, rounded, serif
    
    /// Returns the corresponding Font.Design for each font design option.
    func getFontDesign() -> Font.Design {
        switch self {
        case .standard:
            .default
        case .monospaced:
            .monospaced
        case .rounded:
            .rounded
        case .serif:
            .serif
        }
    }
}

/// Enum for defining the app's font width options.
enum AppFontWidth: String, CaseIterable {
    case compressed, condensed, expanded, standard
    
    /// Returns the corresponding Font.Width for each font width option.
    func getFontWidth() -> Font.Width {
        switch self {
        case .compressed:
            .compressed
        case .condensed:
            .condensed
        case .expanded:
            .expanded
        case .standard:
            .standard
        }
    }
}

/// Enum for defining the app's font size options.
enum AppFontSize: String, CaseIterable {
    case xsmall, small, medium, large, xlarge
    
    /// Returns the corresponding DynamicTypeSize for each font size option.
    func getFontSize() -> DynamicTypeSize {
        switch self {
        case .xsmall:
            .xSmall
        case .small:
            .small
        case .medium:
            .medium
        case .large:
            .large
        case .xlarge:
            .xLarge
        }
    }
}

// MARK: - Preview Provider
struct AppSettings_Previews: PreviewProvider {
    static var previews: some View {
        Text("AppSettings Preview")
            .environmentObject(AppSettings())
    }
}
