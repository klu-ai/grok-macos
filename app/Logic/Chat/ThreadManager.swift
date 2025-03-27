//
//  ThreadManager.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 3/02/25.
//
//  Overview:
//  This file defines the ThreadManager class, which centralizes all thread and message management
//  operations for the Grok macOS assistant. It provides a single point of responsibility for 
//  creating, deleting, and editing threads, as well as retrieving messages in a consistent way.
//
//  Core Responsibilities:
//  - Thread creation and deletion
//  - Message sorting and retrieval
//  - Thread title editing
//  - Helper methods for common operations (e.g., fetching recent threads)
//
//  Implementation Details:
//  - Utilizes SwiftData's ModelContext for persisting threads and messages
//  - Designed to be used by view models and views that need to manipulate threads
//  - Ensures consistent thread management across the application
//
//  Usage:
//  - Instantiate with a ModelContext
//  - Use methods to create, delete, and update threads
//  - Retrieve sorted messages for display
//

import Foundation
import SwiftData

@MainActor
class ThreadManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Thread Operations
    
    /// Creates and returns a new Thread with an optional title
    /// - Parameter title: Optional title for the thread
    /// - Returns: The newly created Thread instance
    func createThread(title: String? = nil) -> Thread {
        let newThread = Thread()
        newThread.title = title
        modelContext.insert(newThread)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save modelContext when creating thread: \(error)")
        }
        return newThread
    }
    
    /// Deletes a thread and its associated messages
    /// - Parameter thread: The thread to delete
    func deleteThread(_ thread: Thread) {
        // The Thread-to-Message relationship is defined with cascade delete,
        // so deleting a thread will automatically delete its messages
        modelContext.delete(thread)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save modelContext when deleting thread: \(error)")
        }
    }
    
    /// Returns sorted messages for a given thread
    /// - Parameter thread: The thread to get messages for
    /// - Returns: Array of messages sorted by timestamp in ascending order
    func sortedMessages(for thread: Thread) -> [Message] {
        return thread.messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Updates the title of a thread
    /// - Parameters:
    ///   - thread: The thread to update
    ///   - title: The new title for the thread
    func updateThreadTitle(_ thread: Thread, title: String) {
        thread.title = title
        do {
            try modelContext.save()
        } catch {
            print("Failed to save modelContext when updating thread title: \(error)")
        }
    }
    

    
    // MARK: - Message Operations
    
    /// Creates a message and adds it to a thread
    /// - Parameters:
    ///   - role: The role of the message sender (user, assistant, system)
    ///   - content: The content of the message
    ///   - thread: The thread to add the message to
    ///   - generatingTime: Optional time taken to generate the message
    /// - Returns: The newly created Message instance
    func createMessage(role: Role, content: String, thread: Thread, generatingTime: TimeInterval? = nil, messageType: MessageType = .text, toolCallId: String? = nil) -> Message {
        let message = Message(role: role, content: content, thread: thread, generatingTime: generatingTime, messageType: messageType, toolCallId: toolCallId)
        thread.messages.append(message)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save modelContext when creating message: \(error)")
        }
        return message
    }
    
    /// Deletes a message from its thread
    /// - Parameter message: The message to delete
    func deleteMessage(_ message: Message) {
        modelContext.delete(message)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save modelContext when deleting message: \(error)")
        }
    }
} 