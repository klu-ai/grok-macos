//
//  Main.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  This file is the main entry point for the Klu macOS Assistant. It initializes the application
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
//  - appKlu built for macOS 15 Sequoia and does not support earlier versions
//  - Apple Silicon Macs required for running models locally
//

import SwiftUI        // Import SwiftUI framework for building user interfaces.
import SwiftData      // Import SwiftData for data modeling and persistence.
import AppKit         // Import AppKit for macOS-specific window management.

/// The main entry point of the Klu Assistant macOS app.
@main
struct kluApp: App {
    /// Integrates the custom AppDelegate for handling application-level events.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// A shared instance of WindowManager for managing window state.
    @StateObject private var windowManager = WindowManager.shared
    
    /// The onboarding manager to handle onboarding state
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    /// Shared PermissionManager instance for centralized permission handling
    @StateObject private var permissionManager = PermissionManager()
    
    /// The preferences manager to handle app-wide settings
    @AppStorage("showInMenuBar") private var showInMenuBar = true

    /// The app manager responsible for coordinating application-wide state and functionality
    @StateObject var appSettings: AppSettings
    
    /// The currently selected thread in the conversation
    @State var currentThread: Thread?
    
    /// Tracks whether the prompt input field is focused
    @FocusState var isPromptFocused: Bool
    
    /// Shared model container for SwiftData using a defined schema.
    /// This container is responsible for data persistence and management.
    private let sharedModelContainer: ModelContainer
    
    /// Manages LLM response generation
    @StateObject private var runLLM: RunLLM
    
    /// The view model that manages the chat interface state, including sessions and current input.
    @StateObject private var viewModel: ChatViewModel

    /// Holds a reference to the current NSWindow.
    @State private var window: NSWindow?
    
    /// Environment variable to track the scene phase (active, inactive, background).
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Initialization
    /// Initializes the RunLLM, ChatViewModel, and sharedModelContainer instances with proper dependency injection.
    init() {
        // Initialize sharedModelContainer
        let schema = Schema([
            Message.self,
            Thread.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Create a PermissionManager instance first
        let permissionManagerInstance = PermissionManager()
        self._permissionManager = StateObject(wrappedValue: permissionManagerInstance)
        
        // Create an AppSettings instance with the permission manager
        let appInstance = AppSettings(permissionManager: permissionManagerInstance)
        self._appSettings = StateObject(wrappedValue: appInstance)
        
        // Create runLLMInstance with AppManager reference
        let runLLMInstance = RunLLM()
        runLLMInstance.appSettings = appInstance
        self._runLLM = StateObject(wrappedValue: runLLMInstance)
        
        // Extract modelContext as a local constant
        let modelContext = sharedModelContainer.mainContext
        self._viewModel = StateObject(wrappedValue: ChatViewModel(runLLM: runLLMInstance, modelContext: modelContext, appSettings: appInstance))
    }
    
    // MARK: - Scene Definition
    /// The body of the application, defining the user interface and behavior.
    var body: some Scene {
        // Define the main window group for the app.
        WindowGroup("Klu Assistant") {
            AssistantView(currentThread: $currentThread, viewModel: viewModel, runLLM: runLLM)
                .environmentObject(appSettings)
                .environmentObject(permissionManager)
                .modelContainer(sharedModelContainer)
                .sheet(isPresented: .init(
                    get: { !onboardingManager.isOnboardingComplete },
                    set: { _ in }
                )) {
                    Onboarding()
                    .environmentObject(runLLM)
                    .environmentObject(permissionManager)
                    .environmentObject(appSettings)
                }
        }
        // Ensure only one window is created by handling external events
        .handlesExternalEvents(matching: Set(arrayLiteral: "kluAssistant"))
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
                    } else if let window = NSApp.windows.first(where: { $0.title.contains("Klu Assistant") }) {
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
        MenuBarExtra(isInserted: Binding(get: { showInMenuBar }, set: { newValue in
            // We explicitly dispatch to the main queue to safely update showInMenuBar
            DispatchQueue.main.async {
                showInMenuBar = newValue
            }
        })) {
            MenuBarContentView()
                .environmentObject(windowManager)
        } label: {
            // Load and resize the image using NSImage.
            let image: NSImage = {
                guard let img = NSImage(named: "MenuBarIcon") else { return NSImage() }
                // Calculate desired width based on desired height (18 points)
                let desiredHeight: CGFloat = 18
                let ratio = img.size.width / img.size.height
                img.size = CGSize(width: desiredHeight * ratio, height: desiredHeight)
                return img
            }()
            Image(nsImage: image)
        }
        .menuBarExtraStyle(.menu)

        // Define the settings scene using a custom PreferencesView.
        Settings {
            PreferencesView()
            .environmentObject(appSettings)
            .environmentObject(runLLM)
            .environmentObject(permissionManager)
        }
    }
}
