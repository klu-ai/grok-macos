//
//  Message.swift
//  klu macos assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Overview:
//  This file contains the data models for chat messages and threads used in the Klu macOS assistant.
//  It leverages SwiftData for persistent storage and management of chat history.
//
//  Core Models:
//  - Message: Represents individual chat messages with attributes for role, content, and timestamps.
//  - Thread: Represents a collection of related messages, providing organization and sorting capabilities.
//
//  Features:
//  - Unique identifiers for each message and thread.
//  - Automatic timestamping for message creation.
//  - Role-based attribution for messages (assistant, user, system).
//  - Relationship management between messages and threads.
//
//  Implementation Details:
//  - Utilizes SwiftData's @Model for defining data models.
//  - Supports persistent storage and retrieval of chat data.
//  - Provides sorted access to messages within a thread.
//
//  Usage:
//  - Store and retrieve chat messages.
//  - Organize messages into threads.
//  - Track and manage chat history.
//

import Foundation
import SwiftData

enum Role: String, Codable {
    case assistant
    case user
    case system
    case tool
}

/// Defines the types of messages that can be displayed in the chat
enum MessageType: Codable {
    case text
    case toolCall(name: String, id: String)
    case toolResult(toolCallId: String)
}

@Model
class Message {
    @Attribute(.unique) var id: UUID
    var role: Role
    var content: String
    var timestamp: Date
    var generatingTime: TimeInterval?
    var messageType: MessageType = MessageType.text

    var toolCallId: String?
    
    @Relationship(inverse: \Thread.messages) var thread: Thread?
    
    init(role: Role, content: String, thread: Thread? = nil, generatingTime: TimeInterval? = nil, 
         messageType: MessageType = .text, toolCallId: String? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.thread = thread
        self.generatingTime = generatingTime
        self.messageType = messageType
        self.toolCallId = toolCallId
    }
}


/// Note: When modifying Thread instances off the main thread, ensure to use DispatchQueue.main.async
/// or mark functions with @MainActor to perform updates on the main thread.

@Model
final class Thread {
    @Attribute(.unique) var id: UUID
    var title: String?
    var timestamp: Date
    
    @Relationship var messages: [Message] = []
    
    var sortedMessages: [Message] {
        return messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
    }
}
