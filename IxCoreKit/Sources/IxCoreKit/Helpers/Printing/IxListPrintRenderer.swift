//
//  IxListPrintRenderer.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 14/02/26.
//

import UIKit
import CoreGraphics
import OSLog

private let log = Logger.uiLogger

final class IxListPrintRenderer: UIPrintPageRenderer {
    
    private let list: IxList
    private let categoryToItemsMap: [IxListCategory?:[IxListItem]]
    private let config: ListExportConfig
    private let totalItemsCount: Int
    
    private static let horizontalMargin: CGFloat = 24
    private static let verticalMargin: CGFloat = 24
    private static let spaceAfterListName: CGFloat = 8
    private static let spaceAfterCategoryName: CGFloat = 6
    private static let spaceAfterLastItem: CGFloat = 10
    private static let iconSize: CGFloat = 14
    private static let iconHorizontalSpace: CGFloat = 4
    
    private static let listNameFont = UIFont.boldSystemFont(ofSize: 22)
    private static let categoryNameFont = UIFont.boldSystemFont(ofSize: 16)
    private static let itemFont = UIFont.systemFont(ofSize: 14)
    private static let noteFont = UIFont.systemFont(ofSize: 12)
    
    private var itemsPerPage: [[IxListCategory?:[IxListItem]]] = []
    
    init(
        list: IxList,
        categoryToItemsMap: [IxListCategory?:[IxListItem]],
        config: ListExportConfig
    ) {
        self.list = list
        self.categoryToItemsMap = categoryToItemsMap
        self.config = config
        self.totalItemsCount = categoryToItemsMap.values.reduce(0) { $0 + $1.count }
        super.init()
    }
    
    override func prepare(forDrawingPages range: NSRange) {
        super.prepare(forDrawingPages: range)
        calculatePaginatedItems()
    }
    
    override var numberOfPages: Int {
        calculatePaginatedItems()
        return itemsPerPage.count
    }
    
    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        guard pageIndex < itemsPerPage.count else { return }
        let categoriesToItems = itemsPerPage[pageIndex]
        let printableRect = contentRect.insetBy(dx: Self.horizontalMargin, dy: Self.verticalMargin)
        
        var y = printableRect.minY
        
        let listColor = UIColor(self.list.color.toColor())

        if pageIndex == 0 {
            let listName = self.list.name as NSString
            let listNameHeight = self.list.name.height(using: Self.listNameFont, width: printableRect.width * 0.7)
            listName.draw(
                in: CGRect(
                    x: printableRect.minX,
                    y: y,
                    width: printableRect.width * 0.7,
                    height: listNameHeight
                ),
                withAttributes: [
                    .font: Self.listNameFont,
                    .foregroundColor: listColor
                ]
            )
            
            let countString = "\(self.totalItemsCount)" as NSString
            countString.draw(
                in: CGRect(
                    x: printableRect.maxX - 60,
                    y: y,
                    width: 60,
                    height: listNameHeight
                ),
                withAttributes: [
                    .font: Self.listNameFont,
                    .paragraphStyle: self.rightAligned(),
                    .foregroundColor: listColor
                ]
            )
            
            y += listNameHeight + Self.spaceAfterListName
        }
        
        for (mapIndex, (category, items)) in categoriesToItems.enumerated() {
            if let category = category {
                let categoryHeight = category.name.height(using: Self.categoryNameFont, width: printableRect.width)
                category.name.draw(
                    in: CGRect(x: printableRect.minX, y: y, width: printableRect.width, height: categoryHeight),
                    withAttributes: [.font: Self.categoryNameFont]
                )
                y += categoryHeight + Self.spaceAfterCategoryName
            }
            
            for (index, item) in items.enumerated() {
                let icon = item.completed ? "circle.inset.filled" : "circle"
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: Self.iconSize)
                let image = UIImage(systemName: icon, withConfiguration: symbolConfig)
                image?.draw(in: CGRect(x: printableRect.minX, y: y + 2, width: Self.iconSize, height: Self.iconSize))
                
                let itemX = printableRect.minX + Self.iconSize + Self.iconHorizontalSpace
                let itemWidth = printableRect.width - Self.iconSize - Self.iconHorizontalSpace

                let itemHeight = item.name.height(using: Self.itemFont, width: itemWidth)
                item.name.draw(
                    in: CGRect(x: itemX, y: y, width: itemWidth, height: itemHeight),
                    withAttributes: [.font: Self.itemFont]
                )

                y += itemHeight

                if config.includeItemLinks,
                   let linkString = item.link,
                   !linkString.isEmpty,
                   let url = URL(string: linkString) {
                    var displayText = linkString
                    if displayText.hasPrefix("https://") {
                        displayText.removeFirst("https://".count)
                    } else if displayText.hasPrefix("http://") {
                        displayText.removeFirst("http://".count)
                    }

                    let linkHeight = displayText.height(using: Self.noteFont, width: itemWidth)
                    let linkRect = CGRect(x: itemX, y: y, width: itemWidth, height: linkHeight)

                    displayText.draw(
                        in: linkRect,
                        withAttributes: [
                            .font: Self.noteFont,
                            .foregroundColor: listColor
                        ]
                    )

                    if let context = UIGraphicsGetCurrentContext() {
                        context.setURL(url as CFURL, for: linkRect)
                    }

                    y += linkHeight
                }

                if let note = item.note, config.includeItemNotes, !note.isEmpty {
                    let noteHeight = note.heightLimited(
                        using: Self.noteFont,
                        width: itemWidth,
                        maxLines: config.itemNotesMaxLines
                    )
                    note.draw(
                        in: CGRect(x: itemX, y: y, width: itemWidth, height: noteHeight),
                        withAttributes: [
                            .font: Self.noteFont,
                            .foregroundColor: UIColor.secondaryLabel
                        ]
                    )
                    y += noteHeight
                }
                
                let last = (index == items.count - 1) && (mapIndex != categoriesToItems.count - 1)
                if last {
                    y += Self.spaceAfterLastItem
                }
            }
        }
    }
}

extension IxListPrintRenderer {
    func calculatePaginatedItems() {
        itemsPerPage.removeAll()
        
        let printable = printableRect.insetBy(dx: Self.horizontalMargin, dy: Self.verticalMargin)
        let width = printable.width
        var remainingHeight = printable.height
        var categoryToItemsForPage: [IxListCategory?:[IxListItem]] = [:]
        
        let listNameH = list.name.height(using: Self.listNameFont, width: width)
        remainingHeight -= listNameH
        remainingHeight -= Self.spaceAfterListName
        
        func commitPage() {
            if !categoryToItemsForPage.isEmpty {
                itemsPerPage.append(categoryToItemsForPage)
            }
            categoryToItemsForPage = [:]
            remainingHeight = printable.height
        }
        
        func subtractCategory(_ category: IxListCategory) {
            let categoryNameH = category.name.height(using: Self.categoryNameFont, width: width)
            remainingHeight -= categoryNameH
            remainingHeight -= Self.spaceAfterCategoryName
        }
        
        func subtractItem(_ item: IxListItem, last: Bool) {
            let itemWidth = width - Self.iconSize - Self.iconHorizontalSpace
            let itemNameH = item.name.height(using: Self.itemFont, width: itemWidth)
            remainingHeight -= itemNameH

            if config.includeItemLinks,
               let linkString = item.link,
               !linkString.isEmpty,
               let _ = URL(string: linkString) {
                var displayText = linkString
                if displayText.hasPrefix("https://") {
                    displayText.removeFirst("https://".count)
                } else if displayText.hasPrefix("http://") {
                    displayText.removeFirst("http://".count)
                }

                let linkHeight = displayText.height(using: Self.noteFont, width: itemWidth)
                remainingHeight -= linkHeight
            }

            if let note = item.note, config.includeItemNotes, !note.isEmpty {
                remainingHeight -= note.heightLimited(
                    using: Self.noteFont,
                    width: itemWidth,
                    maxLines: config.itemNotesMaxLines
                )
            }

            if last {
                remainingHeight -= Self.spaceAfterLastItem
            }
        }
        
        for (mapIndex, (category, items)) in categoryToItemsMap.enumerated() {
            if let category = category {
                subtractCategory(category)
                if remainingHeight <= 0 {
                    commitPage()
                    subtractCategory(category)
                }
                categoryToItemsForPage.updateValue([], forKey: category)
            }
            
            for (index, item) in items.enumerated() {
                let last = (index == items.count - 1) && (mapIndex != categoryToItemsForPage.count - 1)
                subtractItem(item, last: last)
                if remainingHeight <= 0 {
                    commitPage()
                    subtractItem(item, last: last)
                }
                categoryToItemsForPage[category, default: []].append(item)
            }
        }
        
        commitPage()
    }
    
    func rightAligned() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        return style
    }
}
