//
//  IxWidgetDependencies.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents
import IxCoreKit

actor IxWidgetDependencies {
    @MainActor
    static func setup() async {
        AppDependencyManager.shared.add(dependency: ModelContainerProvider.shared)
        AppDependencyManager.shared.add(dependency: IxApiClient { _ in })
    }
}
