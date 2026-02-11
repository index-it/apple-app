//
//  NextTaskConfigurationWidgetIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/02/26.
//

import AppIntents

struct NextTaskConfigurationWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Next Task"
    static var description = IntentDescription("Configure the Next Task widget.")
    
    @Parameter(title: "Max Days Ahead", description: "Filter how far in the future the Next Task can be.", default: 1)
    var maxDaysAhead: Int
    
    @Parameter(title: "Non Scheduled", description: "Whether a Task without a due date is elegible", default: false)
    var allowNonScheduled: Bool
    
    @Parameter(
        title: "Minimum Priority",
        description: "Choose a minimum priority that the Task needs to have to be considered."
    )
    var minimumPriority: TaskPriorityEnum?
}
