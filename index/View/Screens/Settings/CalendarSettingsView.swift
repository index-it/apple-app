//
//  CalendarSettings.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/02/26.
//

import EventKit
import SwiftUI
import IxCoreKit

struct CalendarSettingsView: View {
    @Environment(CalendarManager.self) private var calendarManager
    
    @AppStorage(AppStorageKeys.Tasks.showCalendarEvents) var showCalendarEvents: Bool = AppStorageKeys.Defaults.showCalendarEvents
    @State private var calendars: [EKCalendar] = []
    @AppStorage(AppStorageKeys.Tasks.enabledCalendars) private var enabledCalendarIds = AppStorageKeys.Defaults.enabledCalendars
    
    var body: some View {
        Group {
            if calendarManager.permitted {
                permittedView
            } else {
                unpermittedView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Enabled Calendars")
        .onChange(of: calendarManager.permitted, initial: true) { _, permitted in
            if permitted {
                calendars = calendarManager.store.calendars(for: .event)
            }
        }
    }
    
    private var permittedView: some View {
        List {
            if calendarManager.permitted && showCalendarEvents {
                calendarsList
            }
        }
    }
    
    private var unpermittedView: some View {
        ContentUnavailableView {
            Label("Allow Calendar Access", systemImage: "exclamationmark.shield")
        } description: {
            Text("Go into Settings > Apps > Index and enable calendar access to show calendar events in the Tasks list.")
        } actions: {
            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } label: {
                Text("Open Settings")
            }.buttonStyle(.glassProminent)
        }
    }
    
    private var calendarsList: some View {
        let grouped = Dictionary(grouping: calendars, by: { $0.source })
        let sortedSources = grouped.keys.sorted { ($0?.title.lowercased() ?? "") < ($1?.title.lowercased() ?? "") }
        
        return ForEach(sortedSources.enumerated(), id: \.offset) { offset, source in
            Section {
                ForEach(
                    grouped[source]!.sorted { $0.title.lowercased() < $1.title.lowercased() },
                    id: \.calendarIdentifier
                ) { calendar in
                    Button {
                        if enabledCalendarIds.contains(calendar.calendarIdentifier) {
                            enabledCalendarIds.removeAll { $0 == calendar.calendarIdentifier }
                        } else {
                            enabledCalendarIds.append(calendar.calendarIdentifier)
                        }
                    } label: {
                        HStack {
                            Text(calendar.title)
                            Spacer()
                            if enabledCalendarIds.contains(calendar.calendarIdentifier) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundStyle(.foreground)
                }
            } header: {
                Text(source?.title ?? "")
            } footer: {
                if offset == sortedSources.count - 1 {
                    Text("Tap on a Calendar to enable it, tap again to disable it.")
                }
            }
        }
    }
}

#Preview {
    CalendarSettingsView()
}
