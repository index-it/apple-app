//
//  ModelContainerProvider.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftData

/// Provides the model container for SwiftData that includes all the models used by the app. **Autosave is disabled, transactions usage is recommended**
public struct ModelContainerProvider {
    @MainActor
    public static let shared: ModelContainer = {
        do {
            let schema = Schema([IxList.self, IxListCategory.self, IxListItem.self, IxTask.self])
            
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]
            )
            modelContainer.mainContext.autosaveEnabled = false
            
            return modelContainer
        } catch {
            fatalError("Could not create model container: \(error)")
        }
    }()
}
