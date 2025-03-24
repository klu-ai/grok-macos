//
//  Model.swift
// Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Defines the core data structure for representing AI models in the application.
//  This model encapsulates all necessary information about an AI model including
//  its size, capabilities, and resource requirements.
//
//  Key features:
//  - Unique identification of models
//  - Size tracking and memory management
//  - Model capability descriptions
//  - Hashable for collections
//
//  Implementation notes:
//  - Uses UInt64 for precise size representation
//  - Implements Identifiable for SwiftUI integration
//  - Provides GB to bytes conversion utilities
//  - Supports optional descriptions for flexibility
//  - Includes direct URLs for GGUF and MLX downloads via self.gguf and self.mlx
//
//  Dependencies:
//  - Foundation: Provides basic data types and utilities
//
//  Usage:
//  - Used by model providers (CoreModels, etc.)
//  - Referenced in model download and management
//  - Supports model comparison and selection
//

import Foundation

/// A struct representing an AI model with its properties and memory requirements
public struct Model: Identifiable, Hashable {
    /// Unique identifier for the model (same as name)
    public let id: String
    
    /// Name of the model
    public let name: String
    
    /// Human-readable name of the model
    public let displayName: String
    
    /// Model creator/organization
    public let lab: String
    
    /// Size of the model in bytes
    public let size: UInt64
    
    /// Optional description of the model's capabilities
    public let description: String?
    /// Direct URL for GGUF format download.
    public let gguf: String?
    /// Direct URL for MLX format download.
    public let mlx: String
    
    /// Initialize a new AI model
    /// - Parameters:
    ///   - name: The name of the model
    ///   - displayName: Human-readable name of the model
    ///   - lab: Model creator/organization
    ///   - sizeInGB: The size of the model in gigabytes
    ///   - description: Optional description of the model
    public init(name: String, displayName: String, lab: String, sizeInGB: Double, description: String? = nil, gguf: String? = nil, mlx: String) {
        self.id = name
        self.name = name
        self.displayName = displayName
        self.lab = lab
        self.size = UInt64(sizeInGB * 1024 * 1024 * 1024) // Convert GB to bytes
        self.description = description
        self.gguf = gguf
        self.mlx = mlx
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Model, rhs: Model) -> Bool {
        lhs.id == rhs.id
    }
} 
