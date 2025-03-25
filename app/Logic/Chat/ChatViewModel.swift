//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Overview:
//  This file defines the ChatViewModel class, which manages the state and logic of the chat interface
//  in the Grok macOS assistant. It organizes conversations into threads and integrates with RunLLM for
//  generating responses. It also integrates with SwiftData's ModelContext for persisting threads and messages.
//
//  Core Responsibilities:
//  - Manages conversations using threads
//  - Generates real-time responses using LLM
//  - Supports creating new threads
//  - Handles user input with immediate feedback
//
//  Implementation Details:
//  - Utilizes SwiftUI's @Published for reactive state management
//  - Integrates with RunLLM for asynchronous response generation
//  - Utilizes ThreadManager for thread and message management
//  - Delegates data persistence to ThreadManager
//
//  Usage:
//  - Instantiate with a RunLLM instance and a ModelContext
//  - Manage chat threads and messages
//  - Generate responses using LLM

import Foundation
import SwiftUI
import SwiftData

class ChatViewModel: ObservableObject {
    // MARK: - Properties
    
    // User's current text input
    @Published var currentInput: String = ""  
    
    // Indicates if the LLM is generating a response
    @Published var isThinking: Bool = false  
    
    // Instance of RunLLM for response generation
    @ObservedObject var runLLM: RunLLM       
    
    // SwiftData context for persisting threads and messages
    let modelContext: ModelContext           
    
    // Thread manager for thread and message operations
    private let threadManager: ThreadManager
    
    // Flag to prevent duplicate message generation
    private var isGeneratingResponse: Bool = false  
    
    // AppSettings instance passed in initializer
    private let appSettings: AppSettings

    // MARK: - Initialization
    init(runLLM: RunLLM, modelContext: ModelContext, appSettings: AppSettings) {
        self.runLLM = runLLM
        self.modelContext = modelContext
        self.threadManager = ThreadManager(modelContext: modelContext)
        self.appSettings = appSettings
    }

    // MARK: - Methods
    
    /// Sends a user message to the specified thread and triggers an LLM response
    /// - Parameters:
    ///   - content: The user's message content
    ///   - thread: The thread to append the message to
    func sendMessage(_ content: String, thread: Thread) {
        guard !content.isEmpty else { return }
        guard !isGeneratingResponse else { return }  // Prevent multiple generations
        
        // Show thinking indicator with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            isThinking = true
        }
        
        // Create and append user message to the thread using ThreadManager
        _ = threadManager.createMessage(role: .user, content: content, thread: thread, messageType: MessageType.text)
        
        // Set flag to prevent duplicate generations
        isGeneratingResponse = true
        
        // Generate LLM response asynchronously
        Task {
            // Use appSettings instance to get system prompt
            let systemPrompt = await MainActor.run {
                appSettings.getSystemPrompt()
            }
            
            let result = await runLLM.generate(thread: thread, systemPrompt: systemPrompt)
            
            // Update UI on main thread in a single operation
            await MainActor.run {
                // Create assistant message with the response
                _ = threadManager.createMessage(role: .assistant, content: result, thread: thread, generatingTime: runLLM.thinkingTime)
                
                // Hide thinking indicator with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    isThinking = false
                }
                
                // Reset generation flag
                isGeneratingResponse = false
            }
        }
    }
    
    /// Creates a new thread and persists it to the model context
    func createNewThread() -> Thread {
        return threadManager.createThread()
    }
    
    /// Creates a new thread with a specified title
    /// - Parameter title: The title for the new thread
    /// - Returns: The newly created thread
    func createNewThread(title: String) -> Thread {
        return threadManager.createThread(title: title)
    }
    
    /// Deletes the specified thread and its messages
    /// - Parameter thread: The thread to delete
    func deleteThread(_ thread: Thread) {
        threadManager.deleteThread(thread)
    }
    
    /// Updates the title of a thread
    /// - Parameters:
    ///   - thread: The thread to update
    ///   - title: The new title for the thread
    func updateThreadTitle(_ thread: Thread, title: String) {
        threadManager.updateThreadTitle(thread, title: title)
    }
    
    /// Returns sorted messages for a thread
    /// - Parameter thread: The thread to get messages for
    /// - Returns: Array of messages sorted by timestamp
    func sortedMessages(for thread: Thread) -> [Message] {
        return threadManager.sortedMessages(for: thread)
    }
    
    /// Stops the LLM from generating a response
    func stopGeneration() {
        runLLM.stop()
        isGeneratingResponse = false
        withAnimation(.easeInOut(duration: 0.1)) {
            isThinking = false
        }
    }
}
