//
//  AppState.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Global application state manager that maintains shared state across the application.
//  Implements the singleton pattern for centralized state management and provides
//  observable properties for SwiftUI view updates.
//
//  Key responsibilities:
//  - Manages global application state
//  - Provides centralized access to shared data
//  - Handles command-driven profile selection
//  - Maintains singleton instance for app-wide access
//
//  Implementation notes:
//  - Uses @Published for SwiftUI state management
//  - Implements singleton via shared static instance
//  - Thread-safe state updates
//
//  Usage:
//  - Access via AppState.shared
//  - Observe state changes in SwiftUI views
//  - Update state through provided methods
//

import Foundation
import SwiftUI

public class AppState: ObservableObject {
    
    static let shared: AppState = AppState()
    
    @Published var commandSelectedProfileId: UUID? = nil
    @Published var appSettings: AppSettings?
    
    static func setCommandSelectedProfileId(_ id: UUID) {
        Self.shared.commandSelectedProfileId = id
    }
    
}
