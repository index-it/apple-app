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
            intent: CreateItemIntent(),
            phrases: [
                "Add item to \(\.$list) in \(.applicationName)",
                "Create an item in \(\.$list)  in \(.applicationName)"
            ],
            shortTitle: "Add Item",
            systemImageName: "note.text.badge.plus",
            parameterPresentation: ParameterPresentation(
                for: \.$list,
                summary: Summary("Add item to \(\.$list)"),
                optionsCollections: {
                    OptionsCollection(IxListEntityQuery(), title: "Add item to a List", systemImageName: "square.grid.2x2.fill")
                }
            )
        )
        
        AppShortcut(
            intent: OpenListIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Open \(\.$target) list in \(.applicationName)",
                "Open the \(\.$target) list in \(.applicationName)"
            ],
            shortTitle: "Open List",
            systemImageName: "note.text.badge.plus",
            parameterPresentation: ParameterPresentation(
                for: \.$target,
                summary: Summary("Open \(\.$target)"),
                optionsCollections: {
                    OptionsCollection(IxListEntityQuery(), title: "Open a List", systemImageName: "square.grid.2x2.fill")
                }
            )
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
