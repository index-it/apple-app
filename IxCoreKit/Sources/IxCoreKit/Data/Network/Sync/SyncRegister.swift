//
//  SyncRegister.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/11/24.
//

import Foundation

public actor SyncRegister {
    // Shared instance for the singleton
    public static let shared = SyncRegister()
    private init() {}

    private var timestamps: [String: Int64?] = [:]

    /// Gets the timestamp corresponding to the `resource`
    public func get(_ resource: String) -> Int64? {
        return timestamps[resource] ?? nil
    }

    /// Saves the new timestamp for the `resource`
    public func save(_ resource: String, _ timestamp: Int64?) {
        timestamps[resource] = timestamp
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
    public func hasExpired(_ resource: String, threshold: Int64 = 120_000) -> Bool {
        let ts = get(resource)
        let now = Date.now.timeMillis()

        if ts == nil || (now - (ts ?? 0) > threshold) {
            save(resource, now)
            return true
        } else {
            return false
        }
    }

    /// Resets the state by clearing the timestamps.
    public func clear() {
        timestamps.removeAll()
    }
}
