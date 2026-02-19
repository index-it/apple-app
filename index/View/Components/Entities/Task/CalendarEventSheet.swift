//
//  CalendarEventButton.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 19/02/26.
//

import SwiftUI
import EventKit
import EventKitUI
import IxCoreKit

struct CalendarEventSheet: UIViewControllerRepresentable {
    var task: IxTask
    var eventStore: EKEventStore
    var onEventCreated: () -> Void
    
    private let calendar = DateHelper.localCalendar()
    
    var startDate: Date {
        guard let dueDate = task.dueDate else { return Date.now }
        
        if let reminder = task.reminders.first(where: { $0.daysBefore == 0 }) {
            return reminder.asDate(taskDueDate: dueDate)
        } else {
            if calendar.isDate(dueDate, inSameDayAs: Date.now) {
                return Date.now.addingTimeInterval(3600)
            } else {
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dueDate) ?? dueDate
            }
        }
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let event = EKEvent(eventStore: eventStore)
        event.title = task.name
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(3600) // 1 hour
        event.calendar = eventStore.defaultCalendarForNewEvents

        let controller = EKEventEditViewController()
        controller.event = event
        controller.eventStore = eventStore
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onEventCreated: onEventCreated)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        var onEventCreated: () -> Void

        init(onEventCreated: @escaping () -> Void) {
            self.onEventCreated = onEventCreated
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
            
            if action == .saved {
                onEventCreated()
            }
        }
    }
}
