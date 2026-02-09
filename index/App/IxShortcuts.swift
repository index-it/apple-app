//
//  IxAppShortcutsProvider.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 09/02/26.
//

import AppIntents

struct IxShorcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .grayGreen }
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateListIntent(),
            phrases: [
                "Create a list in \(.applicationName)",
                "Add a list in \(.applicationName)"
            ],
            shortTitle: "Create List",
            systemImageName: "text.pad.header.badge.plus"
        )
        
        AppShortcut(
            intent: NavigateIntent(),
            phrases: [
                "Navigate in \(.applicationName)",
                "Navigate to \(\.$navigationOption) in \(.applicationName)"
            ],
            shortTitle: "Navigate",
            systemImageName: "arrowshape.forward"
        )
    }
}
