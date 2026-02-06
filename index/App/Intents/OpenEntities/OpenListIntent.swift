//
//  OpenListIntent.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents
import IxCoreKit

/// Note: there is also a protocol TargetContentProvidingIntent that let's you handle the navigation part in SwiftUI
/// I prefer using universal links for now

@available(iOS 26.0, *)
struct OpenListIntent: OpenIntent, URLRepresentableIntent {
    static let title: LocalizedStringResource = "Open List"

    @Parameter(title: "List", requestValueDialog: "Which list?")
    var target: IxListEntity
}
