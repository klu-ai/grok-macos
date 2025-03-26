//
//  AssistantView.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/25/25.
//
//  Description:
//  This file defines the AssistantView, which serves as the main interface for interacting with
//  the Grok Assistant. It provides a split view layout with a sidebar for thread navigation and
//  a detail view for chat interactions. The view integrates with the app's state management
//  and provides toolbar actions for creating new threads and accessing settings.
//
//  Core responsibilities:
//  - Displays a split view with a sidebar for thread selection and a detail view for chat
//  - Manages the visibility of the sidebar
//  - Provides toolbar actions for creating new threads and accessing settings
//  - Updates the main window reference in the WindowManager
//
//  Usage:
//  - The AssistantView is instantiated with bindings to the current thread and state objects
//  - The view updates dynamically based on the app's state and user interactions
//  - Toolbar actions allow users to create new threads and access settings
//

import SwiftUI
import SwiftData

/// The main view for the Grok Assistant, providing a split view interface for thread navigation and chat interaction.
struct AssistantView: View {
    /// Binding to the currently selected thread in the conversation.
    @Binding var currentThread: Thread?
    
    /// State object for managing the chat interface state.
    @StateObject var viewModel: ChatViewModel
    
    /// State object for managing LLM response generation.
    @StateObject var runLLM: RunLLM
    
    /// Environment object for managing application-wide state and functionality.
    @EnvironmentObject var appSettings: AppSettings
    
    /// Focus state for managing the prompt input field focus.
    @FocusState var isPromptFocused: Bool
    
    /// State for holding a reference to the current NSWindow.
    @State private var window: NSWindow?
    
    /// Reference to WindowManager for sidebar state persistence
    @ObservedObject private var windowManager = WindowManager.shared
    
    /// Environment object for managing onboarding.
    @EnvironmentObject var onboardingManager: OnboardingManager
    
    /// The body of the AssistantView, defining the user interface and behavior.
    var body: some View {
        ZStack {
            // Define a split view with a sidebar for thread navigation and a detail view for chat.
            NavigationSplitView(columnVisibility: Binding(
                get: { windowManager.sidebarVisibility },
                set: { windowManager.updateSidebarVisibility($0) }
            )) {
                // Sidebar for selecting threads.
                ThreadsSidebar(
                    currentThread: $currentThread,
                    isPromptFocused: $isPromptFocused
                    //createNewThread: { viewModel.createNewThread() },
                    //sidebarVisibility: $sidebarVisibility
                )
                .environmentObject(viewModel)
                
            } detail: {
                // Detail view for chat interactions.
                ChatView(
                    viewModel: viewModel, 
                    currentThread: $currentThread, 
                    externalIsFocused: $isPromptFocused
                )
                    .environmentObject(runLLM)
                    .environmentObject(appSettings)
                    .frame(minWidth: 300, minHeight: 400)
            }
            .toolbar {
                
                ToolbarItem(placement: .navigation) {
                    Button(action: { currentThread = viewModel.createNewThread() }) {
                        Image(systemName: "plus")
                    }
                    .help("New Thread")
                }
                
                // Toolbar item for accessing settings.
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink {
                        Image(systemName: "gear")
                    }
                }
            }
            .background(
                // Accessor for updating the main window reference.
                WindowAccessor(window: $window)
                    .onChange(of: window) { _, newWindow in
                        WindowManager.shared.updateMainWindow(newWindow)
                    }
            )
            .onAppear {
                // Update the main window reference when the view appears.
                if let win = window {
                    WindowManager.shared.updateMainWindow(win)
                }
            }
        }
        .preferredColorScheme(appSettings.preferredColorScheme)
    }
}

struct AssistantView_Previews: PreviewProvider {
    static var previews: some View {
        let config = SwiftData.ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! SwiftData.ModelContainer(for: Message.self, configurations: config)
        let appSettings = AppSettings()
        let runLLM = RunLLM()
        let viewModel = ChatViewModel(runLLM: runLLM, modelContext: container.mainContext, appSettings: appSettings)
        AssistantView(currentThread: .constant(nil), viewModel: viewModel, runLLM: runLLM)
            .environmentObject(appSettings)
            .environmentObject(OnboardingManager.shared)
            .environmentObject(WindowManager.shared)
            .modelContainer(container)
    }
}
