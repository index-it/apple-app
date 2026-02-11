//
//  ListConfigurationIntent.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 11/02/26.
//

import AppIntents

struct ListConfigurationWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select List"
    static var description = IntentDescription("Selects the list to display information for.")

    // TODO: FIX - Make non optional when compiler fix error
    @Parameter(title: "List")
    var list: IxListEntity?
    
    @Parameter(title: "Filter with category", description: "Whether to show only items that belong to a category", default: false)
    var filterByCategory: Bool
    
    @Parameter(title: "Category", description: "The category to use as filter")
    var category: IxListCategoryEntity?

    init(list: IxListEntity) {
        self.list = list
//        self.filterByCategory = filterByCategory
    }

    init() {}
}
