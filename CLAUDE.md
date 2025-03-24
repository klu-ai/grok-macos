# Klu macOS Assistant Development Guide

## Build & Test Commands
- Build: `xcodebuild -scheme klu -project klu.xcodeproj -configuration Debug build | tee build_log.txt`
- Clean Build: `xcodebuild clean && xcodebuild -scheme klu -project klu.xcodeproj -configuration Debug build`
- Run app after build (without confirmation): `open -a klu.app`

## Code Style Guidelines
- Follow MVVM architecture with SwiftUI
- Use Swift naming conventions: camelCase for properties/methods, PascalCase for types
- Add file header with filename, appname, created by, and date
- Keep views small and focused (avoid "massive" views)
- Use SwiftUI for UI, fallback to UIKit only when necessary
- Leverage modern Swift: async/await, Combine, property wrappers (@MainActor, @Published)
- Use descriptive variable names (isRecording vs go)
- For booleans, use prefixes like is, has, or should
- Handle optionals safely with proper unwrapping
- Prefer structs over classes where possible
- Use lazy loading for large content (LazyVStack, LazyHStack)
- Perform heavy work off the main thread
- Properly handle permissions for privacy-sensitive features
- Always run build command after changes to verify
- Add detailed error handling with appropriate error types
- When working with LLM/ML models, implement memory usage guardrails

For detailed conventions, see `.cursor/rules/macos-swift.mdc`