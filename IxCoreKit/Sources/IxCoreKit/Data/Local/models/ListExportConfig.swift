//
//  ListExportFormat.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 14/02/26.
//


public enum ListExportFormat: String, CaseIterable {
    case pdf = "PDF";
    case image = "Image";
    case text = "Text";
}

public struct ListExportConfig {
    public let format: ListExportFormat
    public let useMarkdown: Bool
    public let filterByCategory: Bool
    public let categoryIdFilter: String?
    public let includeCompletedItems: Bool
    public let includeItemLinks: Bool
    public let includeItemNotes: Bool
    public let itemNotesMaxLines: Int
    
    public init(
        format: ListExportFormat,
        useMarkdown: Bool,
        filterByCategory: Bool,
        categoryIdFilter: String?,
        includeCompletedItems: Bool,
        includeItemLinks: Bool,
        includeItemNotes: Bool,
        itemNotesMaxLines: Int
    ) {
        self.format = format
        self.useMarkdown = useMarkdown
        self.filterByCategory = filterByCategory
        self.categoryIdFilter = categoryIdFilter
        self.includeCompletedItems = includeCompletedItems
        self.includeItemLinks = includeItemLinks
        self.includeItemNotes = includeItemNotes
        self.itemNotesMaxLines = itemNotesMaxLines
    }
}
