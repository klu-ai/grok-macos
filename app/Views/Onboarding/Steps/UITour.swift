//  UITour.swift
//  klu macos assistant
//  Created by Stephen M. Walker II on 3/14/24.

//
// Description:
// The UITour view forms a core component of the onboarding process in the Grok macOS assistant.
// It guides new users through essential app features by presenting a series of interactive tour steps
// that highlight areas such as the chat interface, session sidebar, quick actions, menu bar access,
// and application preferences.
//
// Key Features:
// - Guided Onboarding Flow: Sequentially introduces users to the app's main functionalities through
//   descriptive tour steps.
// - Dynamic Progress Indicator: Presents a set of progress dots that update in real time to show
//   the current tour step.
// - Modular Step Configuration: Utilizes a structured tourSteps array where each step is defined
//   with a title, description, image, and positional attribute for flexible UI presentation.
// - Intuitive Visual Layout: Leverages SwiftUI's view hierarchy to create a clean and responsive
//   interface, following Tailwindcss-inspired design principles.
//
// Section Types:
// - Onboarding UI Components: Contains all elements required for presenting the guided tour,
//   including state management for tracking tour steps.
// - Tour Step Model: Defines the data structure for individual tour steps, ensuring each step can
//   easily be updated or extended.
// - Interactive Visual Elements: Incorporates progress dots and layout containers (VStack, HStack)
//   to provide clear visual cues and smooth navigation.
//
// Notes:
// - Built with SwiftUI, the view effectively adapts to various macOS window sizes while maintaining
//   a modern aesthetic.
// - The design adheres to Tailwindcss-inspired styling conventions through the consistent use of
//   color and spacing, applied using SwiftUI modifiers.
// - Each tour step is self-contained, allowing developers to easily customize the tour by updating
//   the tourSteps array without altering the core logic.
//
// Usage:
// - Display the UITour view as part of the initial onboarding sequence to familiarize new users
//   with key app areas.
// - Modify the tourSteps array to add, remove, or update steps according to changes in app
//   functionality or design.
// - Integrate this view in modal or embedded formats to provide a flexible and comprehensive user
//   guidance solution.


import SwiftUI

/// The UI tour step of the onboarding process.
struct UITour: View {
    @State private var currentTourStep = 0
    
    // Tour steps data
    private let tourSteps = [
        TourStep(
            title: "Chat Interface",
            description: "This is where you'll interact with Grok. Type your messages here and see Grok's responses.",
            image: "chat.bubble.2",
            position: .center
        ),
        TourStep(
            title: "Session Sidebar",
            description: "View and manage your chat sessions. Each session maintains its own context and history.",
            image: "sidebar.left",
            position: .left
        ),
        TourStep(
            title: "Quick Actions",
            description: "Access common actions and tools quickly from the toolbar.",
            image: "bolt",
            position: .top
        ),
        TourStep(
            title: "Menu Bar Access",
            description: "Quickly access Grok from the menu bar icon, even when the main window is closed.",
            image: "menubar.rectangle",
            position: .top
        ),
        TourStep(
            title: "Preferences",
            description: "Customize Grok's behavior, appearance, and integrations from the Preferences window.",
            image: "gearshape",
            position: .right
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<tourSteps.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentTourStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top)
            
            // Main content
            VStack(spacing: 30) {
                // Interface preview with highlight
                ZStack {
                    // App interface mockup
                    InterfaceMockup(highlightPosition: tourSteps[currentTourStep].position)
                        .frame(height: 250)
                    
                    // Highlight overlay
                    HighlightOverlay(position: tourSteps[currentTourStep].position)
                }
                
                // Step icon
                if #available(macOS 15.0, *) {
                    Image(systemName: tourSteps[currentTourStep].image)
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .symbolEffect(.bounce)
                } else {
                    Image(systemName: tourSteps[currentTourStep].image)
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        
                }
                
                // Step information
                VStack(spacing: 10) {
                    Text(tourSteps[currentTourStep].title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(tourSteps[currentTourStep].description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 400)
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if currentTourStep > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentTourStep -= 1
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(currentTourStep < tourSteps.count - 1 ? "Next" : "Finish") {
                    withAnimation {
                        if currentTourStep < tourSteps.count - 1 {
                            currentTourStep += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Supporting Types

/// Represents a step in the UI tour
private struct TourStep {
    let title: String
    let description: String
    let image: String
    let position: HighlightPosition
}

/// Positions where the highlight can appear
enum HighlightPosition {
    case left, right, top, bottom, center
}

// MARK: - Supporting Views

/// A mockup of the app interface
private struct InterfaceMockup: View {
    let highlightPosition: HighlightPosition
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 200)
                .overlay {
                    if highlightPosition == .left {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .padding(4)
                    }
                }
            
            // Main content
            Rectangle()
                .fill(Color.gray.opacity(0.05))
                .overlay {
                    if highlightPosition == .center {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .padding(4)
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            // Toolbar highlight
            if highlightPosition == .top {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 40)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    }
                    .padding(4)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

/// An overlay that highlights different parts of the interface
private struct HighlightOverlay: View {
    let position: HighlightPosition
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.2)
                
                // Clear "hole" for the highlighted area
                let highlightFrame = highlightFrame(in: geometry)
                Path { path in
                    path.addRect(geometry.frame(in: .local))
                    path.addRoundedRect(in: highlightFrame, cornerSize: CGSize(width: 8, height: 8))
                }
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(.clear)
            }
        }
    }
    
    private func highlightFrame(in geometry: GeometryProxy) -> CGRect {
        let size = CGSize(width: 200, height: 100)
        var origin: CGPoint
        
        switch position {
        case .left:
            origin = CGPoint(x: 10, y: (geometry.size.height - size.height) / 2)
        case .right:
            origin = CGPoint(x: geometry.size.width - size.width - 10,
                           y: (geometry.size.height - size.height) / 2)
        case .top:
            origin = CGPoint(x: (geometry.size.width - size.width) / 2, y: 10)
        case .bottom:
            origin = CGPoint(x: (geometry.size.width - size.width) / 2,
                           y: geometry.size.height - size.height - 10)
        case .center:
            origin = CGPoint(x: (geometry.size.width - size.width) / 2,
                           y: (geometry.size.height - size.height) / 2)
        }
        
        return CGRect(origin: origin, size: size)
    }
}

// MARK: - Preview Provider
struct UITour_Previews: PreviewProvider {
    static var previews: some View {
        UITour()
            .frame(width: 600, height: 500)
    }
} 
