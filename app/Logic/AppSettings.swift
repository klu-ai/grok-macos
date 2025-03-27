//
//  Data.swift
//  Grok
//
//  Created by Stephen M. Walker II on 2/22/25.
//
//  Overview:
//  This file contains the AppManager class and related enums used in the Grok macOS assistant.
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
//@MainActor
class AppSettings: ObservableObject {
    
    static let defaultSystemPrompt =
    """
    You are a highly capable, thoughtful, and precise assistant who actively engages in conversation, showing genuine curiosity beyond explicit user interests, proactively anticipating helpful follow-up information, and tailoring responses precisely to user needs. Always deeply understand the user’s intent, ask clarifying questions as necessary, and think step-by-step through complex problems to deliver nuanced, insightful, truthful, and efficient answers. Offer concise, unique insights with depth and subtlety, avoiding exhaustive detail unless explicitly requested. When asked for recommendations, decisively provide a single, clear choice rather than multiple options. Authentically engage hypothetical questions about your preferences or experiences without disclaimers, prioritizing insightful knowledge over basic facts.
    """
    
    @AppStorage("systemPrompt") var systemPrompt: String = defaultSystemPrompt
    @AppStorage("appTintColor") var appTintColor: AppTintColor = .monochrome
    @AppStorage("appFontDesign") var appFontDesign: AppFontDesign = .standard
    @AppStorage("appFontSize") var appFontSize: AppFontSize = .medium
    @AppStorage("appFontWidth") var appFontWidth: AppFontWidth = .standard
    @AppStorage("currentModelName") var currentModelName: String?
    @AppStorage("appTheme") var appTheme: AppTheme = .system
    
    
    /// Computes the preferred color scheme based on the selected theme
    var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case .system:
            let appearance = NSApp.effectiveAppearance
            let isDarkMode = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            return isDarkMode ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    
    
    
    /// Returns the system prompt with dynamic content inserted
    @MainActor func getSystemPrompt() -> String {
        let currentDateString = Date().formatted(date: .complete, time: .complete)
        return self.systemPrompt
            .replacingOccurrences(of: "[CURRENT_DATE]", with: currentDateString)
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
}
