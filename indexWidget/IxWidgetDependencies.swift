//
//  IxWidgetDependencies.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

actor IxWidgetDependencies {
    private static var isSetup = false

    @MainActor
    static func setup() async {
        if !isSetup {
            isSetup = true
            AppDependencyManager.shared.add(dependency: ModelContainerProvider.shared)
            AppDependencyManager.shared.add(dependency: IxApiClient { _ in })
        }
    }
}
