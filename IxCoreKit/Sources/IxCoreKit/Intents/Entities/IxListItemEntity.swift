//
//  IxListItemEntity.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents

@available(iOS 26.0, *)
struct IxListItemEntity: IndexedEntity {
    static let defaultQuery = IxListItemEntityQuery()
    
    var id: String
    
    @Property(indexingKey: \.title)
    var name: String
    
    @Property
    var completed: Bool
    
    @Property(indexingKey: \.contentURL)
    var link: String?
    
    @Property(indexingKey: \.contentDescription)
    var note: String?
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Item", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) items"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: note != nil ? "\(note!)" : nil)
    }
    
    init(item: IxListItem) {
        self.id = item.id
        self.name = item.name
        self.completed = item.completed
        self.link = item.link
        self.note = item.note
    }
}

// cannot add listId to the interpolation yet
//@available(iOS 26.0, *)
//extension IxListItemEntity: URLRepresentableEntity {
//    static var urlRepresentation: URLRepresentation {
//        URLRepresentation(stringLiteral: "https://web.index-it.app/lists/\(.listId)/items/\(.id)")
//    }
//}
