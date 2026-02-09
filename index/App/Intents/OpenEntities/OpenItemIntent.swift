//
//  OpenItemIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

@available(iOS 26.0, *)
struct OpenItemIntent: OpenIntent, URLRepresentableIntent {
    static let title: LocalizedStringResource = "Open Item"

    @Parameter(title: "Item", requestValueDialog: "Which item?")
    var target: IxListItemEntity
}
