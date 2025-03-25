//
//  Main.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 3/24/25.
//
//  Description:
//  This file is the main entry point for the Grok macOS Assistant. It initializes the application
//  environment, sets up persistent data storage, manages window behavior, and integrates
//  system-level features like onboarding and menu commands.
//
//  Core responsibilities:
//  - Initializes the main window using WindowManager and ensures proper activation and focus
//  - Configures a SwiftData ModelContainer for persisting chat sessions and messages
//  - Manages user onboarding flow via OnboardingManager
//  - Provides a reactive chat interface with session-based conversation handling
//  - Implements a MenuBarExtra for quick access to app functionality
//  - Defines application commands and keyboard shortcuts
//  - Integrates a Settings scene for system configuration
//  - Reacts to scene phase changes to maintain window state
//
//  Usage:
//  - The app initializes the main window, data storage, and chat interface at launch
//  - The WindowManager keeps the app window visible and responsive
//  - A MenuBarExtra provides quick access to the assistant
//  - User onboarding runs until setup is complete
//  - Preferences and integrations are configured through the Settings scene
//
//  Dependencies:
//  - SwiftUI for UI components
//  - SwiftData for data persistence
//  - AppKit for macOS-specific window management
//  - appGrok built for macOS 15 Sequoia and does not support earlier versions
//  - Apple Silicon Macs required for running models locally
//

import SwiftUI        // Import SwiftUI framework for building user interfaces.
import SwiftData      // Import SwiftData for data modeling and persistence.
import AppKit         // Import AppKit for macOS-specific window management.

/// The main entry point of the Grok Assistant macOS app.
@main
struct grokApp: App {
    /// Shared AppSettings instance for managing app-wide settings
    @StateObject private var appSettings: AppSettings
    
    /// Shared RunLLM instance for managing AI model execution
    @StateObject private var runLLM = RunLLM()
    
    /// Shared OnboardingManager instance for managing onboarding state
    @StateObject private var onboardingManager = OnboardingManager()
    
    /// Shared WindowManager instance for managing window state
    @StateObject private var windowManager = WindowManager()
    
    /// The container for managing the app's persistent data
    let container: ModelContainer
    
    /// The currently selected thread in the conversation
    @State var currentThread: Thread?
    
    /// Tracks whether the prompt input field is focused
    @FocusState var isPromptFocused: Bool
    
    /// The view model that manages the chat interface state, including sessions and current input.
    @StateObject private var viewModel: ChatViewModel
    
    /// Holds a reference to the current NSWindow.
    @State private var window: NSWindow?
    
    /// Environment variable to track the scene phase (active, inactive, background).
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Initialization
    /// Initializes the RunLLM, ChatViewModel, and sharedModelContainer instances with proper dependency injection.
    init() {
        // Configure the ModelContainer for SwiftData
        do {
            container = try ModelContainer(for: Message.self)
        } catch {
            fatalError("Failed to create ModelContainer for Message: \(error.localizedDescription)")
        }
        
        // Initialize AppSettings
        self._appSettings = StateObject(wrappedValue: AppSettings())
        
        // Create runLLMInstance with AppManager reference
        let runLLMInstance = RunLLM()
        runLLMInstance.appSettings = appSettings
        self._runLLM = StateObject(wrappedValue: runLLMInstance)
        
        // Extract modelContext as a local constant
        let modelContext = container.mainContext
        self._viewModel = StateObject(wrappedValue: ChatViewModel(runLLM: runLLMInstance, modelContext: modelContext, appSettings: appSettings))
    }
    
    // MARK: - Scene Definition
    /// The body of the application, defining the user interface and behavior.
    var body: some Scene {
        // Define the main window group for the app.
        WindowGroup("Grok Assistant") {
            AssistantView(currentThread: $currentThread, viewModel: viewModel, runLLM: runLLM)
                .environmentObject(appSettings)
                .environmentObject(runLLM)
                .environmentObject(onboardingManager)
                .environmentObject(windowManager)
                .modelContainer(container)
                .sheet(isPresented: .init(
                    get: { !onboardingManager.isOnboardingComplete },
                    set: { _ in }
                )) {
                    Onboarding()
                    .environmentObject(runLLM)
                    .environmentObject(onboardingManager)
                    .environmentObject(appSettings)
                }
        }
        // Ensure only one window is created by handling external events
        .handlesExternalEvents(matching: Set(arrayLiteral: "grokAssistant"))
        .defaultSize(width: 1000, height: 700)
        .defaultPosition(.center)

        // removed these to get the big toolbar
        //.windowStyle(.hiddenTitleBar)
        //.windowToolbarStyle(.unified(showsTitle: true))
        
        // Define commands for menu actions and keyboard shortcuts
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(action: {
                    // Create a new thread
                    let newThread = viewModel.createNewThread()
                    
                    // Set it as the current thread - this should update the sidebar selection 
                    // via the .onChange(of: currentThread) in ThreadsSidebar
                    currentThread = newThread
                    
                    // Set focus to the prompt input field
                    isPromptFocused = true
                    
                    // Ensure the selection is properly made by adding a small delay
                    // This helps with UI synchronization issues
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Set currentThread again to ensure binding triggers properly
                        currentThread = newThread
                        // Set focus again after the delay to ensure it takes effect
                        isPromptFocused = true
                    }
                    
                    // Ensure window is brought to focus when creating a new chat
                    // First check if a window already exists in the array of windows
                    if let existingMainWindow = windowManager.mainWindow {
                        // If we already have a reference to the main window, use it
                        windowManager.updateMainWindow(existingMainWindow)
                    } else if let window = NSApp.windows.first(where: { $0.title.contains("Grok Assistant") }) {
                        // Otherwise find the window by title and use it
                        windowManager.updateMainWindow(window)
                    }
                    
                    // This is now handled by handlesExternalEvents directive to prevent new window creation
                }) {
                    Label("New Chat", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()
 
                Button("Reset Onboarding") {
                    onboardingManager.resetOnboarding()
                }
                .keyboardShortcut("r", modifiers: [.command, .option])
            }
            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar", action: {
                    // Toggle using the standard AppKit method
                    NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar), to: nil, from: nil)
                    
                    // Toggle the stored state in WindowManager
                    // We invert the current state since the AppKit action just toggled it
                    WindowManager.shared.updateSidebarState(collapsed: !WindowManager.shared.isSidebarCollapsed)
                })
                .keyboardShortcut("s", modifiers: .command)
                
                Divider()
            }
        }
        // React to scene phase changes
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let win = window {
                windowManager.updateMainWindow(win)
            }
        }
        
        // Provide a MenuBarExtra (if enabled in AppStorage)
        MenuBarExtra(isInserted: Binding(get: { true }, set: { _ in })) {
            MenuBar()
                .modelContainer(container)
                .environmentObject(appSettings)
                .environmentObject(runLLM)
                .environmentObject(onboardingManager)
                .environmentObject(windowManager)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)

        // Define the settings scene using a custom PreferencesView.
        Settings {
            PreferencesView()
                .modelContainer(container)
                .environmentObject(appSettings)
                .environmentObject(runLLM)
                .environmentObject(onboardingManager)
                .environmentObject(windowManager)
        }
    }
}
