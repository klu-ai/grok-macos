# Grok - macOS AI Assistant

<img width="868" alt="image" src="https://github.com/user-attachments/assets/8db01500-1467-483b-91a1-9cf676f29cbe" />

Grok is a modern macOS AI assistant that seamlessly integrates with your system, providing an intuitive chat interface and comprehensive system integration capabilities. Built with SwiftUI and leveraging the latest macOS features, it offers a powerful and user-friendly experience.

## Features

### Core Features
- Modern SwiftUI interface with split view navigation
- Menu bar and dock integration with quick access controls
- Dark/Light mode support with native macOS styling
- Session-based chat interface with message history
- Customizable system preferences and settings
- Guided onboarding experience for new users

### System Integration
- Calendar and reminders integration
- Contacts access for personalized assistance
- Location services for contextual awareness
- File system access for document management
- Email integration with multiple provider support

### Preferences & Customization
- Comprehensive settings interface with categorized sections
- Customizable notification preferences
- Hardware optimization settings
- Browsing preferences with multiple browser support
- Message history and chat appearance settings

### Onboarding Experience
- Step-by-step guided setup process
- AI model download and initialization
- System permissions configuration
- Initial preferences customization
- Interactive UI tour
- Progress tracking and resume capability

## Project Structure  

```
app/
├── Views/                                  # User interface components
│   ├── Onboarding/                         # Onboarding experience
│   │   ├── Onboarding                  # Main onboarding container
│   │   └── Steps/                          # Individual onboarding steps
│   │       ├── WelcomeStep                 # Initial welcome screen
│   │       ├── ModelDownloadStep           # AI model setup
│   │       ├── PermissionsStep            # System permissions
│   │       ├── PreferencesStep            # Initial preferences
│   │       ├── UITourStep                 # Interface walkthrough
│   │       └── CompletionStep             # Setup completion
│   ├── Chat/                               # Main chat interface
│   │   ├── MessageBubble                   # Message display components
│   │   └── ChatView                        # Primary chat view implementation
│   ├── Messages/                           # Message handling and display
│   │   ├── SessionSidebar                  # Chat session navigation
│   │   └── MessageBubble                   # Message styling and layout
│   ├── Preferences/                        # Settings and preferences UI
│   │   ├── Layout/                         # Preference window layout components
│   │   │   ├── Sidebar                     # Navigation sidebar
│   │   │   └── Content                     # Main content area
│   │   └── Sections/                       # Individual preference sections
│   │       ├── General                     # General app settings
│   │       ├── Hardware                    # System resource management
│   │       ├── Calendar                    # Calendar integration settings
│   │       ├── Email                       # Email configuration
│   │       ├── Messages                    # Chat preferences
│   │       ├── Browsing                    # Browser integration
│   │       ├── Notifications               # Notification settings
│   │       └── Permissions                 # System permission management
│   └── Sessions/                           # Sessions sidebar views
├── Logic/                                  # Core app logic
│   ├── Models/                             # AI and data models
│   │   ├── Model                         # Base AI model definitions
│   │   ├── CoreModels                      # Core data structures
│   │   ├── AudioModels                     # Audio processing models
│   │   ├── VisionModels                    # Vision processing models
│   │   ├── ReasoningModels                 # Reasoning capabilities
│   │   └── EmbeddingModels                 # Text embedding models
│   ├── Chat/                               # Chat functionality
│   │   ├── ChatViewModel                   # Chat business logic
│   │   └── Message                         # Message data model
│   ├── Browsing/                           # Browser integration
│   │   ├── whitelist                       # Allowed domains
│   │   └── blacklist                       # Blocked domains
│   ├── WindowManager                       # Window state management
│   ├── PreferenceSection                   # Preferences organization
│   └── WindowAccessor                      # Window access control
│   ├── OnboardingManager                   # Onboarding state management
```

## Additional Components

### LoginItemHelper
A separate module that manages the app's launch-at-login functionality.

### Documentation
- `docs/`: Comprehensive documentation directory
- `.github/`: GitHub-specific configurations and workflows

### LLM Integration
The app includes a sophisticated LLM (Large Language Model) integration system:
- `Config.swift`: Manages LLM configuration and settings
- `Run.swift`: Handles LLM execution and response processing

## System Requirements

- macOS 15.0 or later
- Required Permissions:
  - Calendar access
  - Contacts access
  - Location services
  - File system access
  - Notifications
  - Camera (optional)
  - Microphone (optional)
  - Siri (optional)

## Setup

1. Clone the repository
2. Open `grok-macos.xcodeproj` in Xcode
3. Build and run the project
4. Complete the guided onboarding process:
   - Welcome and introduction
   - Download required AI models
   - Configure system permissions
   - Set initial preferences
   - Take the UI tour
   - Begin using Grok

## Configuration

### General Settings
- Launch at login option
- Menu bar visibility toggle
- Dock presence configuration
- Automatic updates checking

### Message Settings
- Customizable message history retention
- Auto-save intervals
- Message appearance customization
- Typing indicators and read receipts

### Integration Settings
- Email provider configuration
- Calendar sync preferences
- Browser integration options
- Hardware optimization settings

## Development

- Built with SwiftUI and modern Swift concurrency
- Follows MVVM architecture
- Supports macOS native features
- Includes comprehensive UI tests

## Version

Current Version: 1.0
Bundle Identifier: humans.grok
Minimum macOS Version: 15.0
