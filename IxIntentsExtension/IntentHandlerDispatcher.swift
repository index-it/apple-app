//
//  GenericHandler.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 21/02/26.
//

import Intents

class IntentHandlerDispatcher: INExtension {
    override func handler(for intent: INIntent) -> Any? {
        switch intent {
        case is INCreateNoteIntent:
            return AddItemIntentHandler()
        case is INAddTasksIntent:
            return AddTaskIntentHandler()
        default:
            return nil
        }
    }
}
