//
//  CalendarPreferences.swift
//  Grok macOS assistant
//
//  Created by Stephen M. Walker II on 2/12/25.
//
//  Description:
//  Manages calendar integration and scheduling preferences for the application.
//  Provides comprehensive controls for calendar synchronization, event display,
//  and work schedule configuration using the EventKit framework.
//
//  Key features:
//  - Calendar service integration
//  - Event visibility controls
//  - Work schedule management
//  - Sync interval configuration
//  - Multiple calendar support
//
//  Calendar management:
//  - Default calendar selection
//  - Event filtering options
//  - Past/future event windows
//  - Work day configuration
//  - Week schedule customization
//
//  Implementation notes:
//  - Uses EventKit for calendar access
//  - Implements sync scheduling
//  - Manages calendar permissions
//  - Handles calendar selection
//
//  Time management:
//  - Work hours configuration
//  - Work week customization
//  - Event window preferences
//  - Sync frequency control
//
//  Usage:
//  - Select default calendar
//  - Configure work schedule
//  - Set event visibility
//  - Manage sync settings
//

import SwiftUI
import EventKit

/// View for managing calendar-related preferences and settings.
struct CalendarPreferences: View {
    // MARK: - State Properties
    @AppStorage("calendarEnabled") private var calendarEnabled = false
    @AppStorage("defaultCalendarId") private var defaultCalendarId = ""
    @AppStorage("calendarSyncInterval") private var calendarSyncInterval = 5
    @AppStorage("showDeclinedEvents") private var showDeclinedEvents = false
    @AppStorage("showPastEvents") private var showPastEvents = true
    @AppStorage("pastEventsDays") private var pastEventsDays = 7
    @AppStorage("futureEventsDays") private var futureEventsDays = 30
    @AppStorage("workDayStart") private var workDayStart = 9
    @AppStorage("workDayEnd") private var workDayEnd = 17
    @AppStorage("workWeekDaysString") private var workWeekDaysString = "2,3,4,5,6" // Mon-Fri
    
    // State for available calendars
    @State private var availableCalendars: [EKCalendar] = []
    @State private var selectedCalendar: EKCalendar?
    
    // Available sync intervals (in minutes)
    private let syncIntervals = [1, 5, 15, 30, 60]
    
    // Hours for work day selection
    private let hours = Array(0...23)
    
    // Days of the week
    private let weekDays = [
        (id: 1, name: "Sun"),
        (id: 2, name: "Mon"),
        (id: 3, name: "Tue"),
        (id: 4, name: "Wed"),
        (id: 5, name: "Thu"),
        (id: 6, name: "Fri"),
        (id: 7, name: "Sat")
    ]
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Calendar Integration", isOn: $calendarEnabled)
                    .help("Enable calendar features in Grok")
            } footer: {
                Text("Connect your calendar to manage events and schedule meetings directly from Grok.")
            }
            
            if calendarEnabled {
                Section("Calendar Selection") {
                    Picker("Default Calendar", selection: $selectedCalendar) {
                        ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                            HStack {
                                Circle()
                                    .fill(Color(cgColor: calendar.cgColor))
                                    .frame(width: 12, height: 12)
                                Text(calendar.title)
                            }
                            .tag(Optional(calendar))
                        }
                    }
                    .help("Select your default calendar for new events")
                    
                    Button("Refresh Calendars") {
                        loadAvailableCalendars()
                    }
                }
                
                Section("Sync Settings") {
                    Picker("Sync Interval", selection: $calendarSyncInterval) {
                        ForEach(syncIntervals, id: \.self) { interval in
                            Text("\(interval) \(interval == 1 ? "minute" : "minutes")")
                                .tag(interval)
                        }
                    }
                    .help("Choose how often to sync calendar events")
                }
                
                Section("Event Display") {
                    Toggle("Show Declined Events", isOn: $showDeclinedEvents)
                        .help("Display events you've declined")
                    
                    Toggle("Show Past Events", isOn: $showPastEvents)
                        .help("Display events that have already occurred")
                    
                    if showPastEvents {
                        Stepper("Past Events: \(pastEventsDays) days", value: $pastEventsDays, in: 1...90)
                            .help("Number of past days to show events from")
                    }
                    
                    Stepper("Future Events: \(futureEventsDays) days", value: $futureEventsDays, in: 1...365)
                        .help("Number of future days to show events for")
                }
                
                Section("Work Schedule") {
                    HStack {
                        Picker("Work Day Start", selection: $workDayStart) {
                            ForEach(hours, id: \.self) { hour in
                                Text(formatHour(hour))
                                    .tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 100)
                        
                        Text("to")
                        
                        Picker("Work Day End", selection: $workDayEnd) {
                            ForEach(hours, id: \.self) { hour in
                                Text(formatHour(hour))
                                    .tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 100)
                    }
                    .help("Set your typical work day hours")
                    
                    // Updated binding to work directly on workWeekDaysString to avoid immutability issues.
                    WorkWeekSelector(selectedDays: Binding(
                        get: { workWeekDaysString.split(separator: ",").compactMap { Int($0) } },
                        set: { newDays in workWeekDaysString = newDays.map(String.init).joined(separator: ",") }
                    ))
                    .help("Select your working days")
                }
                
                Section("Actions") {
                    Button("Sync Now") {
                        syncCalendar()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear Calendar Cache") {
                        clearCalendarCache()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadAvailableCalendars()
        }
        .onChange(of: selectedCalendar) { oldCalendar, newCalendar in
            if let newCalendar {
                defaultCalendarId = newCalendar.calendarIdentifier
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadAvailableCalendars() {
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        DispatchQueue.main.async {
            self.availableCalendars = calendars.sorted { $0.title < $1.title }
            if let defaultCalendar = calendars.first(where: { $0.calendarIdentifier == defaultCalendarId }) {
                self.selectedCalendar = defaultCalendar
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date)
    }
    
    private func syncCalendar() {
        // Here you would implement the calendar sync functionality
        // This is a placeholder for the actual implementation
    }
    
    private func clearCalendarCache() {
        // Here you would implement the calendar cache clearing functionality
        // This is a placeholder for the actual implementation
    }
}

// MARK: - WorkWeekSelector
/// A custom view for selecting work days of the week.
struct WorkWeekSelector: View {
    @Binding var selectedDays: [Int]
    
    private let weekDays = [
        (id: 1, name: "S"),
        (id: 2, name: "M"),
        (id: 3, name: "T"),
        (id: 4, name: "W"),
        (id: 5, name: "T"),
        (id: 6, name: "F"),
        (id: 7, name: "S")
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.id) { day in
                Button(action: {
                    toggleDay(day.id)
                }) {
                    Text(day.name)
                        .font(.system(.body, design: .rounded))
                        .frame(width: 32, height: 32)
                        .background(selectedDays.contains(day.id) ? Color.accentColor : Color.clear)
                        .foregroundStyle(selectedDays.contains(day.id) ? .white : .primary)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.removeAll { $0 == day }
        } else {
            selectedDays.append(day)
            selectedDays.sort()
        }
    }
}

// MARK: - Preview Provider
struct CalendarPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarPreferences()
    }
} 
