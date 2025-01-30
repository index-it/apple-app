//
//  SyncRegister.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation

class SyncRegister {
    // Shared instance for the singleton
    static let shared = SyncRegister()
    
    struct ResourceNames {
        static let LISTS = "lists"
        static let TASKS = "tasks"
        static let COMPLETED_TASKS = "completed-tasks"
        static let SUGGESTION_COLORS = "suggestion-colors"
        
        static func list(_ listId: String) -> String {
            return "\(LISTS)/\(listId)"
        }
        
        static func listItem(_ listId: String, _ itemId: String) -> String {
            return "\(LISTS)/\(listId)/\(itemId)"
        }
        
        static func listItemContent(_ listId: String, _ itemId: String) -> String {
            return "\(LISTS)/\(listId)/\(itemId)/content"
        }
        
        static func task(_ taskId: String) -> String {
            return "\(TASKS)/\(taskId)"
        }
    }
    
    // Private initializer to prevent direct instantiation
    private init() {}
    
    private var syncTimestamps: [String: Int64?] = [:]
    
    /// Gets the timestamp corresponding to the `resource`
    func get(_ resource: String) -> Int64? {
        return syncTimestamps[resource] ?? nil
    }
    
    /// Saves the new timestamp for the `resource`
    func save(_ resource: String, timestamp: Int64?) {
        syncTimestamps[resource] = timestamp
    }
    
    /**
     Gets the timestamp for `resource`,
     checks if it's nil or above the `threshold` (default 2 minutes),
     updates the timestamp with the current time and returns true,
     otherwise returns false.
     
     - Parameters:
        - resource: The resource identifier.
        - threshold: The time threshold in milliseconds (default is 120,000 ms or 2 minutes).
     
     - Returns: `true` if the timestamp is older than the threshold or is nil, `false` otherwise.
     */
    func getCheckAndUpdate(_ resource: String, threshold: Int64 = 120000) -> Bool {
        let ts = get(resource)
        let now = Int64(Date().timeIntervalSince1970 * 1000) // Current time in milliseconds
        
        if ts == nil || (now - (ts ?? 0) > threshold) {
            save(resource, timestamp: now)
            return true
        } else {
            return false
        }
    }
    
    /// Resets the state by clearing the timestamps.
    func resetState() {
        syncTimestamps.removeAll()
    }
}
