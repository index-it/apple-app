//
//  IxListEntity.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents

// TODO: Implement Transferrable protocol
@available(iOS 26.0, *)
struct IxListEntity: IndexedEntity {
    static let defaultQuery = IxListEntityQuery()
    
    var id: String
    
    @Property(indexingKey: \.title)
    var name: String
    
    @Property
    var icon: String
    
    @Property
    var color: String
    
    @Property
    var archived: Bool
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("List", table: "AppIntents", comment: "The type name for the list entity"),
            numericFormat: "\(placeholder: .int) lists"
        )
    }
    
    var displayRepresentation: DisplayRepresentation {
        let image = EmojiHelper.emojiImageData(icon).flatMap { data in
            DisplayRepresentation.Image(data: data, isTemplate: false, displayStyle: .default)
        }
        return DisplayRepresentation(title: "\(name)", image: image)
    }
    
    init(list: IxList) {
        self.id = list.id
        self.name = list.name
        self.icon = list.icon
        self.color = list.color
        self.archived = list.archived
    }
}

@available(iOS 26.0, *)
extension IxListEntity: URLRepresentableEntity {
    static var urlRepresentation: URLRepresentation {
        // cannot use IxUniversalLinks struct to compute this unfortunately
        "https://web.index-it.app/lists/\(.id)"
    }
}
