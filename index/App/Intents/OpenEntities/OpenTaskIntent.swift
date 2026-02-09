//
//  OpenTaskIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

// Note: there is also a protocol TargetContentProvidingIntent that let's you handle the navigation part in SwiftUI
// I prefer using universal links for now

@available(iOS 26.0, *)
struct OpenTaskIntent: OpenIntent, URLRepresentableIntent {
    static let title: LocalizedStringResource = "Open Task"

    @Parameter(title: "Task", requestValueDialog: "Which task?")
    var target: IxTaskEntity
}
