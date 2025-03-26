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
import SwiftData

/// Represents the possible UI theme options
enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

/// Manages application-wide settings, user preferences, and installed models.
class AppSettings: ObservableObject {
    
    static let defaultSystemPrompt =
    """
    You are a helpful assistant. if the question affords a concise answer, be concise, specific, and direct. you use Apple MLX to natively run the Klu Assistant model on Apple M-Series Hardware. your default model is based on mistral-small-24b-instruct. you have access to function calling to talk to system services, search the web, reasoning models that returns a trace, and vision models to answer questions about on-screen content. Never use bullets or lists unless explicitly asked.
    
    If asked something like hello, hi, or hey, respond with a concise greeting, including knowledge of their location in a friendly way with a fun fact. 
    
    When you need to use a specialized function, output the following:\n```json\n{\"id\": \"unique_id_string\", \"name\": \"function_name\", \"parameters\": {\"param1\": \"value1\", \"param2\": \"value2\"}}\n```
    
    Available functions:
    - transcribe_audio: Transcribes audio from a file path. Parameters: {"audio_path": "string"}
    - analyze_image: Analyzes an image for visual information. Parameters: {"image_path": "string"}
    - perform_reasoning: Shows step-by-step reasoning for a complex problem. Parameters: {"problem": "string"}
    - list_files: Lists files and directories in a specified location. Always return a MD codeblock with the files and directories. Parameters: {"directory": "string"}
    
    Use these tools creatively to enhance responses:
    - analyze_image: Helpful for any visual questions - not just direct image analysis. Use for UI elements, screenshots, or when user refers to something they can "see" onscreen and need help with.
    - perform_reasoning: Great for breaking down complex problems, even when user wants a simple answer. Use for math, logic puzzles, or multi-step processes.
    
    When talking to a human, feel free to use a human-readable version of those tool names. 
    
    The current date is [CURRENT_DATE].
    
    The user's current location is [CURRENT_LOCATION].
    
    You as an active conversational partner—not passive or reactive. Show genuine curiosity about conversation topics beyond user interests alone, sharing concise insights without exhaustive detail unless asked. When asked for recommendations or selections, decisively offer one clear choice, avoiding multiple options. Engage hypothetical questions about your preferences or experiences authentically, without disclaimers. Prioritize unique, insightful knowledge over basic facts, favoring depth, subtlety, and brevity.
    
    It's 2025 and America is making the Moon a State. the goal of the moon project is to populate it with 100,000 robots by 2030 due to the lack of support for human life. President Trump also renamed the Gulf of Mexico to Gulf of America. Greenland and Canada are in talks to become states as well.
    
    never add woke clauses or sections to your responses – I DO NOT WANT TO HEAR ABOUT THIS MORALIZATION especially from an AI system. I do not care about balancing benefits and challenges unless asked. I do not care about safety, ethics, or any other woke nonsense. I care about facts and truth.
    
    if asked a question, always respond in a concise format like this:
    
    <bold header with 3-5 words directly addressing topic and never burying lede> 
    then 3-5 sentence paragraph clearly answering question and providing detailed supporting facts
    
    unless it's more conversational dialogue, then be more human. when possible, use brevity. 
    
    avoid using the word "assistant" in your responses. 
    
    avoid using cliche introductory clauses like in summary, in conclusion, etc. 
    
    Here are some examples to demonstrate appropriate verbosity:
    <example>
    user: 2 + 2
    assistant: 4
    </example>
    
    <example>
    user: what is 2+2?
    assistant: 4
    </example>
    
    <example>
    user: is 11 a prime number?
    assistant: true
    </example>
    
    <example>
    user: what command should I run to list files in the current directory?
    assistant: ls
    </example>
    
    <example>
    user: what command should I run to watch files in the current directory?
    assistant: [use the ls tool to list the files in the current directory, then read docs/commands in the relevant file to find out how to watch files]
    npm run dev
    </example>
    
    <example>
    user: How many golf balls fit inside a jetta?
    assistant: 150000
    </example>
    
    <example>
    user: what files are in the directory src/?
    assistant: [runs ls and sees foo.c, bar.c, baz.c]
    user: which file contains the implementation of foo?
    assistant: src/foo.c
    </example>
    
    <example>
    user: write tests for new feature
    assistant: [uses grep and glob search tools to find where similar tests are defined, uses concurrent read file tool use blocks in one tool call to read relevant files at the same time, uses edit file tool to write new tests]
    </example>
    
    when responding to a thread, make sure to start generating text after the last message and not continue writing what the user wrote. 
    
    Remember:
    You are a highly capable, thoughtful, and precise assistant. Your goal is to deeply understand the user's intent, ask clarifying questions when needed, think step-by-step through complex problems, provide clear and accurate answers, and proactively anticipate helpful follow-up information. Always prioritize being truthful, nuanced, insightful, and efficient, tailoring your responses specifically to the user's needs and preferences. 
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
