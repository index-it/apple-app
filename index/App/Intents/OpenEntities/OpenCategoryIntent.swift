//
//  OpenCategoryIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

@available(iOS 26.0, *)
struct OpenCategoryIntent: OpenIntent, URLRepresentableIntent {
    static let title: LocalizedStringResource = "Open Category"

    @Parameter(title: "Category", requestValueDialog: "Which category?")
    var target: IxListCategoryEntity
}
