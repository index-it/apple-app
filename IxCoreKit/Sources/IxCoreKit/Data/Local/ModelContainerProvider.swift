//
//  ModelContainerProvider.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import Foundation
import SwiftData

/// Provides the model container for SwiftData that includes all the models used by the app. **Autosave is disabled, transactions usage is recommended**
@MainActor
public struct ModelContainerProvider {
    public static let shared: ModelContainer = makeModelContainer(isStoredInMemoryOnly: false, autosaveEnabled: false)

    public static func makeModelContainer(isStoredInMemoryOnly: Bool, autosaveEnabled: Bool = false, deleteDatabaseIfMigrationFails: Bool = true) -> ModelContainer {
        do {
            let schema = Schema([IxList.self, IxListCategory.self, IxListItem.self, IxTask.self])

            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)]
            )
            modelContainer.mainContext.autosaveEnabled = false

            return modelContainer
        } catch {
            if deleteDatabaseIfMigrationFails {
                print("erasing")
                deleteSwiftDataStore()
                return makeModelContainer(
                    isStoredInMemoryOnly: isStoredInMemoryOnly,
                    autosaveEnabled: autosaveEnabled,
                    deleteDatabaseIfMigrationFails: false
                )
            } else {
                fatalError("Could not create model container: \(error)")
            }
        }
    }

    private static func deleteDatabase() throws {
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = applicationSupportURL.appending(path: "default.store")

        do {
            if FileManager.default.fileExists(atPath: storeURL.path) {
                try FileManager.default.removeItem(at: storeURL)
                print("Removed corrupted database at: \(storeURL)")
            }
        } catch {
            fatalError("Failed deleting database: \(error)")
        }
    }

    private static func deleteSwiftDataStore() {
        let storeURL = getSwiftDataStoreURL()
        print(storeURL.absoluteString)

        try? FileManager.default.removeItem(at: storeURL)

        // Also remove any related files
        let storeDirectory = storeURL.deletingLastPathComponent()
        let storeName = storeURL.deletingPathExtension().lastPathComponent

        let relatedFiles = [
            storeDirectory.appendingPathComponent("\(storeName)-wal"),
            storeDirectory.appendingPathComponent("\(storeName)-shm"),
        ]

        for file in relatedFiles {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private static func getSwiftDataStoreURL() -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: IxIdentifiers.APP_GROUP) else {
            fatalError("Unable to get App Group container URL")
        }

        return containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("default.store")
    }
}
