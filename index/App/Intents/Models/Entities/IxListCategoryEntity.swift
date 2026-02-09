//
//  IxListCategoryEntity.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents
import IxCoreKit

@available(iOS 26.0, *)
struct IxListCategoryEntity: IndexedEntity {
    static let defaultQuery = IxListCategoryEntityQuery()
    
    var id: String
    
    @Property
    var listId: String
    
    @Property(indexingKey: \.title)
    var name: String
    
    @Property
    var color: String?
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Category", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) categories"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    init(category: IxListCategory) {
        self.id = category.id
        self.listId = category.listId
        self.name = category.name
        self.color = category.color
    }
}

@available(iOS 26.0, *)
extension IxListCategoryEntity: URLRepresentableEntity {
    static var urlRepresentation: URLRepresentation {
        "https://web.index-it.app/lists/\(\.$listId)?categoryId=\(.id)"
    }
}
