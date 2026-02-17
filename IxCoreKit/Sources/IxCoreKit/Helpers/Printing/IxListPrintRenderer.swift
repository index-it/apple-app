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
    private static let spaceAfterListName: CGFloat = 18
    private static let spaceAfterCategoryName: CGFloat = 8
    private static let spaceAfterLastItem: CGFloat = 10
    private static let lineSpacing: CGFloat = 6
    private static let iconSize: CGFloat = 14
    
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
        
        if pageIndex == 0 {
            let listName = self.list.name as NSString
            let listNameHeight = self.list.name.height(using: Self.listNameFont, width: printableRect.width * 0.7)
            let color = UIColor(self.list.color.toColor())
            listName.draw(
                in: CGRect(
                    x: printableRect.minX,
                    y: y,
                    width: printableRect.width * 0.7,
                    height: listNameHeight
                ),
                withAttributes: [
                    .font: Self.listNameFont,
                    .foregroundColor: color
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
                    .foregroundColor: color
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
                
                let itemWidth = printableRect.width - Self.iconSize - 8
                let itemHeight = item.name.height(using: Self.itemFont, width: itemWidth)
                item.name.draw(
                    in: CGRect(x: printableRect.minX + Self.iconSize + 8, y: y, width: itemWidth, height: itemHeight),
                    withAttributes: [.font: Self.itemFont]
                )
                
                y += itemHeight + Self.lineSpacing
                
                if let note = item.note, config.includeItemNotes {
                    let noteHeight = note.heightLimited(
                        using: Self.noteFont,
                        width: itemWidth,
                        maxLines: config.itemNotesMaxLines
                    )
                    note.draw(
                        in: CGRect(x: printableRect.minX + Self.iconSize + 8, y: y, width: itemWidth, height: noteHeight),
                        withAttributes: [.font: Self.noteFont]
                    )
                    y += noteHeight + Self.lineSpacing
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
        let height = printable.height
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
            let itemNameH = item.name.height(using: Self.itemFont, width: width - Self.iconSize - 8)
            remainingHeight -= itemNameH
            remainingHeight -= Self.lineSpacing
            if let note = item.note, config.includeItemNotes {
                remainingHeight -= note.heightLimited(using: Self.noteFont, width: width, maxLines: config.itemNotesMaxLines)
                remainingHeight -= Self.lineSpacing
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
        
        log.debug("Finished calculating paginated items: \(self.itemsPerPage.count) pages: \(self.itemsPerPage)")
    }
    
//    func drawListName(in rect: CGRect) {
//        let name = self.list.name as NSString
//        name.draw(
//            in: CGRect(
//                x: rect.minX,
//                y: rect.minY,
//                width: rect.width * 0.7,
//                height: rect.height
//            ),
//            withAttributes: [
//                .font: Self.listNameFont,
//                .foregroundColor: self.list.color.toColor()
//            ]
//        )
//        
//        let countString = "\(self.totalItemsCount)" as NSString
//        countString.draw(
//            in: CGRect(
//                x: rect.maxX - 60,
//                y: rect.minY,
//                width: 60,
//                height: rect.height
//            ),
//            withAttributes: [
//                .font: Self.listNameFont,
//                .paragraphStyle: self.rightAligned(),
//                .foregroundColor: self.list.color.toColor()
//            ]
//        )
//    }
    
//    func drawPage(_ categoriesToItems: [IxListCategory?:[IxListItem]], in rect: CGRect) {
//        for (category, items) in categoriesToItems {
//            if let category {
//                category.name.draw(
//                    in: rect,
//                    withAttributes: [.font: Self.categoryNameFont]
//                )
//            }
//            
//            for item in items {
//                let icon = item.completed ? "circle.inset.filled" : "circle"
//                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14)
//                let image = UIImage(
//                    systemName: icon,
//                    withConfiguration: symbolConfig
//                )
//                image?.draw(
//                    in: CGRect(
//                        x: rect.minX,
//                        y: rect.minY + 2,
//                        width: Self.iconSize,
//                        height: Self.iconSize
//                    )
//                )
//                
//                item.name.draw(
//                    in: CGRect(
//                        x: rect.minX + Self.iconSize + 8,
//                        y: rect.minY,
//                        width: width - Self.iconSize - 8,
//                        height: titleHeight
//                    ),
//                    withAttributes: [.font: itemFont]
//                )
//                //
//                //                if noteHeight > 0,
//                //                   let note = item.note {
//                //
//                //                    note.draw(
//                //                        in: CGRect(
//                //                            x: rect.minX + self.iconSize + 8,
//                //                            y: rect.minY + titleHeight,
//                //                            width: width - self.iconSize - 8,
//                //                            height: noteHeight
//                //                        ),
//                //                        withAttributes: [.font: noteFont]
//                //                    )
//                //                }
//            }
//        }
//    }
    
//    func buildItemBlocks(
//        items: [IxListItem],
//        width: CGFloat,
//        itemFont: UIFont,
//        noteFont: UIFont
//    ) -> [RenderBlock] {
//        
//        var blocks: [RenderBlock] = []
//        
//        for item in items {
//            
//            let icon = item.completed ? "circle.inset.filled" : "circle"
//            
//            var title = item.name
//            if config.includeItemLinks,
//               let link = item.link,
//               !link.isEmpty {
//                title += " (\(link))"
//            }
//            
//            let titleHeight = title.height(
//                using: itemFont,
//                width: width - iconSize - 8
//            )
//            
//            var noteHeight: CGFloat = 0
//            
//            if config.includeItemNotes,
//               let note = item.note,
//               !note.isEmpty {
//                
//                noteHeight = note.heightLimited(
//                    using: noteFont,
//                    width: width - iconSize - 8,
//                    maxLines: config.itemNotesMaxLines
//                )
//            }
//            
//            let totalHeight = titleHeight + noteHeight + lineSpacing
//            
//            blocks.append(
//                RenderBlock(
//                    draw: { rect in
//                        
//                        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14)
//                        let image = UIImage(
//                            systemName: icon,
//                            withConfiguration: symbolConfig
//                        )
//                        image?.draw(in: CGRect(
//                            x: rect.minX,
//                            y: rect.minY + 2,
//                            width: self.iconSize,
//                            height: self.iconSize
//                        ))
//                        
//                        title.draw(
//                            in: CGRect(
//                                x: rect.minX + self.iconSize + 8,
//                                y: rect.minY,
//                                width: width - self.iconSize - 8,
//                                height: titleHeight
//                            ),
//                            withAttributes: [.font: itemFont]
//                        )
//                        
//                        if noteHeight > 0,
//                           let note = item.note {
//                            
//                            note.draw(
//                                in: CGRect(
//                                    x: rect.minX + self.iconSize + 8,
//                                    y: rect.minY + titleHeight,
//                                    width: width - self.iconSize - 8,
//                                    height: noteHeight
//                                ),
//                                withAttributes: [.font: noteFont]
//                            )
//                        }
//                    },
//                    height: totalHeight
//                )
//            )
//        }
//        
//        return blocks
//    }
//    
    func rightAligned() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        return style
    }
}
