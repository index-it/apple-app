//
//  NavigateIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

@available(iOS 18.0, *)
struct NavigateIntent: AppIntent {
    static let title: LocalizedStringResource = "Navigate to Section"

    static let supportedModes: IntentModes = .foreground
    
    static var parameterSummary: some ParameterSummary {
        Summary("Navigate to \(\.$navigationOption)")
    }

    @Parameter(
        title: "Section",
        requestValueDialog: "Which section?"
    )
    var navigationOption: NavigationOptionEnum
    
    init(navigationOption: NavigationOptionEnum) {
        self.navigationOption = navigationOption
    }
    
    init() {}

    public func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(navigationOption.url))
    }
}
