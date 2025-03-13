//
//  ModelContainerProvider.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftData

struct ModelContainerProvider {
    @MainActor static func get() -> ModelContainer {
        do {
            let schema = Schema([IxList.self, IxListCategory.self, IxListItem.self, IxTask.self])
            
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]
            )
            modelContainer.mainContext.autosaveEnabled = false
            
            return modelContainer
        } catch {
            fatalError("Could not create model container")
        }
    }
}
